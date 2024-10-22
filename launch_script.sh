#!/bin/bash

# Update the system
sudo apt-get update -y
sudo apt-get upgrade -y

# Install dependencies
sudo apt-get install -y python3-pip python3-dev libpq-dev postgresql postgresql-contrib

# Create a PostgreSQL user and database for Airflow
sudo -u postgres psql -c "CREATE USER airflow WITH PASSWORD 'airflow';"
sudo -u postgres psql -c "CREATE DATABASE airflow_db OWNER airflow;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE airflow_db TO airflow;"

# Install Airflow
AIRFLOW_VERSION=2.8.4
CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-3.10-ubuntu-latest.txt"
pip3 install "apache-airflow==${AIRFLOW_VERSION}" --constraint "${CONSTRAINT_URL}"

# Initialize Airflow database
airflow db init

# Create a directory for Airflow and set the necessary environment variables
mkdir -p ~/airflow
export AIRFLOW_HOME=~/airflow
export AIRFLOW__CORE__SQL_ALCHEMY_CONN=postgresql+psycopg2://airflow:airflow@localhost/airflow_db

# Start Airflow services
airflow webserver --daemon --port 8080
airflow scheduler --daemon

# Optional: Display the status of Airflow services
echo "Airflow Web Server and Scheduler are running."
