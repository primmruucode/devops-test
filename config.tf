terraform {
  backend "s3" {
    bucket = "kaidee-tf-state"
    key    = "airflow/ec2.tfstate"
    region = "ap-southeast-1"                           
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.65.0"
    }
  }
}