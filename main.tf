provider "aws" {
    region = var.aws_region
}

resource "aws_security_group" "airflow_security_group" {
  name        = "airflow_security_group"
  description = "Security group to allow inbound SCP & outbound 8080 (Airflow) connections"

  ingress {
    description = "Inbound SCP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "airflow_ec2_security"
  }
}

resource "aws_iam_role" "airflow_iam_role" {
  name = "airflow_iam_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = var.airflow_access_permissions
}

#used to pass an iam role to an ec2 instance 
resource "aws_iam_instance_profile" "airflow_iam_role_instance_profile" {
  name = "airflow_iam_role_instance_profile"
  role = aws_iam_role.airflow_iam_role
}

resource "aws_key_pair" "staging" {
  key_name   = "staging"
  public_key = file("/key/key.pub")
}

############### EC2 INSTANCE ###############
data "aws_ami" "debian" {
    most_recent = true
    owners = ["136693071363"] #Debian project account number
    #filter looking for debian 12 on amd64
    filter {
        name = "name"
        values = ["debian-12-amd64-*"]
    }
}
#Bash script that will execute after image is spun up 
data "template_file" "launch_script" {
    template = "${file(var.launch_script_path)}"
    vars = {for key, item in var.launch_script_variables : key => item}  
}

#awd instance running debian 12

resource "aws_instance" "airflow" {
  ami                    = data.aws_ami.debian.id
  instance_type          = var.instance_type 
  subnet_id              = "subnet-1a2b3c4d"
  key_name               = aws_key_pair.staging.key_name
  vpc_security_group_ids = "vpc-a1b2c3d4"
  private_ip             = "10.0.1.10" 
  security_groups = [airflow_security_group]
  iam_instance_profile = iam_instance_profile.airflow_iam_role_instance_profile.id
  user_data = data.template_file.launch_script

  tags = {
    Name = "staging-airflow"
  }
}
#route53 record
resource "aws_route53_record" "airflow_dns" {
  zone_id = "ABC123" 
  name    = "staging-airflow.kaidee.internal"
  type    = "A"
  ttl     = 300
  records = [aws_instance.airflow.private_ip]
}

output "airflow_private_ip" {
  value = aws_instance.airflow.private_ip
}


output "instance_id" {
  description = "IDs of the EC2 instance"
  value       = aws_instance.airflow.id
}