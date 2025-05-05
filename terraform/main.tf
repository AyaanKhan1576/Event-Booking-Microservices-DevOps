terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  required_version = ">= 1.0.0"
}

provider "aws" {
  region = "us-east-1"
}

# Generate an SSH key pair
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Register the public key in AWS
resource "aws_key_pair" "microservices_key" {
  key_name   = "microservices-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
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

# Create an Internet Gateway
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

# Create a route table & route
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

# Security Group for microservices
resource "aws_security_group" "microservices_sg" {
  name        = "microservices-sg"
  description = "Allow incoming traffic for microservices"
  vpc_id      = aws_vpc.microservices_vpc.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
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

  # All outgoing
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

# Launch EC2 instance
resource "aws_instance" "microservices_instance" {
  ami                         = "ami-0261755bbcb8c4a84" # Amazon Linux 2023
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.microservices_subnet.id
  vpc_security_group_ids      = [aws_security_group.microservices_sg.id]
  key_name                    = aws_key_pair.microservices_key.key_name
  associate_public_ip_address = true
  user_data                   = file("${path.module}/setup_script.sh")

  root_block_device {
    volume_size = 8
    volume_type = "gp2"
  }

  tags = {
    Name = "microservices-instance"
  }
}

# Output the private key for SSH
output "private_key_pem" {
  description = "Private key (PEM format) to SSH into the EC2 instance. Save this as microservices-key.pem"
  value       = tls_private_key.ssh_key.private_key_pem
  sensitive   = true
}

# Output the public IP
output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.microservices_instance.public_ip
}

# Output SSH connection info
output "connection_info" {
  description = "Command to SSH into the instance"
  value       = "ssh -i microservices-key.pem ec2-user@${aws_instance.microservices_instance.public_ip}"
}

# Output service URLs
output "service_urls" {
  description = "Access URLs for your services"
  value = {
    user_service         = "http://${aws_instance.microservices_instance.public_ip}:8000"
    booking_service      = "http://${aws_instance.microservices_instance.public_ip}:5001"
    event_service        = "http://${aws_instance.microservices_instance.public_ip}:5000"
    notification_service = "http://${aws_instance.microservices_instance.public_ip}:5003"
    rabbitmq_management  = "http://${aws_instance.microservices_instance.public_ip}:15672"
  }
}
