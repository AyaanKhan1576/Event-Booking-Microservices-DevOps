terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.0.0"
}

provider "aws" {
  region = "us-east-1" # US East (N. Virginia) region - has good free tier support
}

# Create a VPC
resource "aws_vpc" "microservices_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "microservices-vpc"
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "microservices_igw" {
  vpc_id = aws_vpc.microservices_vpc.id

  tags = {
    Name = "microservices-igw"
  }
}

# Create a public subnet
resource "aws_subnet" "microservices_subnet" {
  vpc_id                  = aws_vpc.microservices_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "microservices-subnet"
  }
}

# Create a route table
resource "aws_route_table" "microservices_rt" {
  vpc_id = aws_vpc.microservices_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.microservices_igw.id
  }

  tags = {
    Name = "microservices-route-table"
  }
}

# Associate the route table with the subnet
resource "aws_route_table_association" "microservices_rta" {
  subnet_id      = aws_subnet.microservices_subnet.id
  route_table_id = aws_route_table.microservices_rt.id
}

# Create a security group for the EC2 instance
resource "aws_security_group" "microservices_sg" {
  name        = "microservices-sg"
  description = "Allow incoming traffic for microservices"
  vpc_id      = aws_vpc.microservices_vpc.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # User service
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Booking service
  ingress {
    from_port   = 5001
    to_port     = 5001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Event service
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Notification service
  ingress {
    from_port   = 5003
    to_port     = 5003
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # RabbitMQ management UI
  ingress {
    from_port   = 15672
    to_port     = 15672
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outgoing traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "microservices-sg"
  }
}

# Create an EC2 instance (t2.micro - free tier eligible)
resource "aws_instance" "microservices_instance" {
  ami                    = "ami-0261755bbcb8c4a84" # Amazon Linux 2023 AMI - update as needed
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.microservices_subnet.id
  vpc_security_group_ids = [aws_security_group.microservices_sg.id]
  key_name               = var.key_pair_name

  user_data = file("${path.module}/setup_script.sh")

  tags = {
    Name = "microservices-instance"
  }

  root_block_device {
    volume_size = 8 # GB - free tier eligible
    volume_type = "gp2"
  }
}

# Output the public IP of the EC2 instance
output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.microservices_instance.public_ip
}

# Output connection instructions
output "connection_info" {
  description = "Instructions to connect to the instance"
  value       = "Connect to your instance using: ssh -i ${var.key_pair_name}.pem ec2-user@${aws_instance.microservices_instance.public_ip}"
}

# Output service URLs
output "service_urls" {
  description = "URLs to access your microservices"
  value = {
    user_service        = "http://${aws_instance.microservices_instance.public_ip}:8000"
    booking_service     = "http://${aws_instance.microservices_instance.public_ip}:5001"
    event_service       = "http://${aws_instance.microservices_instance.public_ip}:5000"
    notification_service = "http://${aws_instance.microservices_instance.public_ip}:5003"
    rabbitmq_management = "http://${aws_instance.microservices_instance.public_ip}:15672"
  }
}