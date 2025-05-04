# CS4067 Event Booking Microservices

### Contributors
- Ayaan Khan (22i-0832)
- Minahil Ali (22i-0849)

## Overview
This repository contains the code for an Event Booking Platform built using a microservices architecture. The system allows users to register, view events, book tickets, and receive booking confirmations via notifications.

### Microservices Breakdown
- **User Service**: Manages user authentication and profiles.
- **Event Service**: Handles event listings and event data.
- **Booking Service**: Processes ticket bookings and manages bookings.
- **Notification Service**: Sends email/SMS notifications to users after booking confirmation.

### Tech Stack

| Component          | Technology Used                      |
|--------------------|--------------------------------------|
| **Frontend (Templates)** | HTML, CSS (Jinja2 via FastAPI)   |
| **User Service**   | FastAPI, PostgreSQL, SQLAlchemy      |
| **Event Service**  | Node.js (Express), MongoDB, Mongoose|
| **Booking Service**| Flask, PostgreSQL, Celery           |
| **Notification Service** | Node.js (Express), MongoDB |
| **Containerization** | Docker                            |
| **Orchestration**  | Kubernetes                          |

## Folder Structure

├── user-service
│ ├── Routes/
│ ├── Static/
│ ├── Templates/
│ ├── auth.py
│ ├── database.py
│ ├── models.py
│ ├── main.py
│ ├── Dockerfile
│ └── ...
│
├── booking-service
│ ├── app/
│ ├── migrations/
│ ├── create_db.py
│ ├── run.py
│ ├── Dockerfile
│ └── ...
│
├── notification-service
│ ├── server.js
│ ├── test-producer.js
│ ├── Dockerfile
│ └── ...
│
├── new-event-service
│ ├── config/
│ ├── controllers/
│ ├── models/
│ ├── routes/
│ ├── server.js
│ ├── Dockerfile
│ └── ...
│
├── kubernetes/
│ ├── user-service-deployment.yaml
│ ├── event-service-deployment.yaml
│ ├── booking-service-deployment.yaml
│ ├── notification-service-deployment.yaml
│ ├── mongo-deployment.yaml
│ ├── postgres-deployment.yaml
│ ├── volumes.yaml
│ ├── configmap.yaml
│ ├── secret.yaml
│ ├── namespace.yaml
│ └── services.yaml
│
└── docker-compose.yml


## Communication Flow

- **User (Frontend)** communicates with the **User Service** and **Event Service / Booking Service**.
- **User Service** handles user registration and authentication.
- **Booking Service** processes ticket bookings.
- **Notification Service** sends notifications via email/SMS upon booking confirmation.
  
REST APIs are used between the **user**, **event**, and **booking** services for communication.

## API Endpoints

- **User Service (FastAPI)**
  - `POST /register`: Register a new user.
  - `POST /login`: Login with credentials.
  - `GET /users/{user_id}`: Get user info.
  - `GET /events`: Retrieve event listings.

- **Event Service (Node.js)**
  - `GET /events`: List all events.
  - `GET /events/{event_id}`: Event details.

- **Booking Service (Flask)**
  - `POST /book`: Book an event.
  - `GET /bookings/{user_id}`: View user’s bookings.

- **Notification Service (Express.js)**
  - `GET /notifications/{user_id}`: View notifications.

## Setup Instructions

1. **Clone the Repository**
    ```bash
    git clone <repo-url>
    cd event-booking-system
    ```

2. **Set Up Environment Variables**
    Create a `.env` file in each microservice directory. Example:

    **User Service `.env`**
    ```
    DATABASE_URL=postgresql://user:password@localhost/userdb
    SECRET_KEY=your_secret_key
    ```

    **Notification Service `.env`**
    ```
    MONGO_URI=mongodb://localhost:27017/notifications
    ```

3. **Run Services Individually (Local Dev)**

    - **PostgreSQL and MongoDB**: Ensure both databases are installed and running locally.

    - **User Service**:
      ```bash
      cd user-service
      pip install -r requirements.txt
      uvicorn main:app --reload --port 8000
      ```

    - **Event Service**:
      ```bash
      cd new-event-service
      npm install
      node server.js
      ```

    - **Booking Service**:
      ```bash
      cd booking-service
      pip install -r requirements.txt
      python create_db.py
      flask run --host=0.0.0.0 --port=5001
      ```

    - **Notification Service**:
      ```bash
      cd notification-service
      npm install
      node server.js
      ```

4. **Docker & Kubernetes**

    - **Docker Compose (for local development)**:
      ```bash
      docker-compose up --build
      ```

    - **Kubernetes (Production-like deployment)**:
      Apply the manifests:
      ```bash
      kubectl apply -f kubernetes/namespace.yaml
      kubectl apply -f kubernetes/configmap.yaml
      kubectl apply -f kubernetes/secret.yaml
      kubectl apply -f kubernetes/volumes.yaml
      kubectl apply -f kubernetes/mongo-deployment.yaml
      kubectl apply -f kubernetes/postgres-deployment.yaml
      kubectl apply -f kubernetes/user-service-deployment.yaml
      kubectl apply -f kubernetes/booking-service-deployment.yaml
      kubectl apply -f kubernetes/event-service-deployment.yaml
      kubectl apply -f kubernetes/notification-service-deployment.yaml
      kubectl apply -f kubernetes/services.yaml
      ```
      ### Kubernetes Commands (Verification & Port Forwarding)
      To verify that your pods and services are running correctly in the Kubernetes namespace:

      ```bash
      kubectl get pods -n microservices-namespace
      kubectl get services -n microservices-namespace
      kubectl describe ingress microservices-ingress -n microservices-namespace
      ```
      To port-forward the user service and access it locally on port 8000:
      
      ```bash
      kubectl port-forward svc/user-service 8000:8000 -n microservices-namespace
      ```


## Git Workflow

1. Create a new branch for your feature:
    ```bash
    git checkout -b feature-branch
    ```

2. Make changes and commit:
    ```bash
    git add .
    git commit -m "Added new feature"
    git push origin feature-branch
    ```
