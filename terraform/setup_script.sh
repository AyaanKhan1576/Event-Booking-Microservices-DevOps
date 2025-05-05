#!/bin/bash

# Update system packages
yum update -y

# Install git
yum install -y git

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.20.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create directory for the project
mkdir -p /home/ec2-user/microservices
cd /home/ec2-user/microservices

# Clone your repository (replace with your actual repository URL)
git clone https://github.com/AyaanKhan1576/Event-Booking-Microservices-DevOps .

# Alternative: Copy docker-compose and microservices from S3 (set up separately)
# aws s3 cp s3://your-bucket/microservices.zip .
# unzip microservices.zip

# Create a placeholder docker-compose.yml file
# (You'll need to upload your actual files through SCP or other means)
cat > docker-compose.yml << 'EOL'
services:
  # User Service
  user-service:
    build:
      context: ./user-service
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://postgres:minahil.ali117@postgres:5432/user_service_db
      - SECRET_KEY=123456789
      - ENV_FILE=/app/.env
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - app-network
    volumes:
      - ./user-service:/app

  # Booking Service
  booking-service:
    build:
      context: ./booking-service
    ports:
      - "5001:5001"
    environment:
      - DATABASE_URL=postgresql://postgres:minahil.ali117@postgres:5432/bookingdb
      - CELERY_BROKER_URL=pyamqp://guest:guest@rabbitmq//
      - SECRET_KEY=123456798
      - ENV_FILE=/app/.env
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - app-network
    volumes:
      - ./booking-service:/app

  # Notification Service
  notification-service:
    build:
      context: ./notification-service
    ports:
      - "5003:5003"
    environment:
      - PORT=5003
      - MONGO_URI=mongodb://mongo:27017/notifications
      - RABBITMQ_URL=amqp://rabbitmq
    depends_on:
      - mongo
      - rabbitmq
    networks:
      - app-network
    volumes:
      - ./notification-service:/app

  # Event Service
  event-service:
    build:
      context: ./new-event-service
    ports:
      - "5000:5000"
    environment:
      - DATABASE_URL=mongodb://mongo:27017/eventdb
      - ENV_FILE=/app/.env
    depends_on:
      - mongo
    networks:
      - app-network
    volumes:
      - ./new-event-service:/app

  # PostgreSQL Database for User Service and Booking Service
  postgres:
    image: postgres:latest
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: minahil.ali117
      POSTGRES_DB: user_service_db
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - app-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  # MongoDB Database for Booking and Event Services
  mongo:
    image: mongo:latest
    environment:
      MONGO_INITDB_DATABASE: eventdb
    volumes:
      - mongo_data:/data/db
    networks:
      - app-network

  # RabbitMQ (for Celery Broker)
  rabbitmq:
    image: rabbitmq:management
    environment:
      RABBITMQ_DEFAULT_USER: guest
      RABBITMQ_DEFAULT_PASS: guest
    ports:
      - "5672:5672"
      - "15672:15672"
    networks:
      - app-network

volumes:
  postgres_data:
  mongo_data:

networks:
  app-network:
    driver: bridge
EOL

# Create a sample init.sql file
cat > init.sql << 'EOL'
CREATE DATABASE IF NOT EXISTS bookingdb;
EOL

# Create empty directories for services
mkdir -p user-service booking-service notification-service new-event-service

# Fix permissions
chown -R ec2-user:ec2-user /home/ec2-user/microservices

# Note: You'll need to upload your actual service code
echo "System setup complete. Please upload your microservice code before running docker-compose up."