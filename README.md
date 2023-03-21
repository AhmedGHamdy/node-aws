
## Terraform Infrastructure Deployment
This Terraform script creates a VPC with a private subnet and an internet gateway, an RDS instance in the private subnet, an ECS Cluster, a task definition for a Node.js application, an ECS service to run the task definition, an ALB (Application Load Balancer), and a security group for the ALB.

### Prerequisites
- AWS account credentials
- Terraform installed on your local machine
- Docker installed on your local machine

### Deployment Steps
- Clone the repository to your local machine.
- Navigate to the project directory.
- Create a terraform.tfvars file and add the required variables.
- Run terraform init to initialize the project.
- Run terraform plan to preview the changes to be made.
- Run terraform apply to apply the changes.
- Resources Created

### This Terraform script creates the following AWS resources:

- VPC with a private subnet and an internet gateway
- Security groups for the RDS instance, ECS service, and ALB
- RDS instance in the private subnet
- ECS Cluster
- Task definition for a Node.js application
- ECS service to run the task definition
- ALB (Application Load Balancer)

### Variables
The following variables are required to deploy this Terraform script:

-aws_region: AWS region where the resources will be deployed (default: us-east-1)
- docker_image_url: URL for the Docker image of the Node.js application
- db_username: Username for the RDS instance
- db_password: Password for the RDS instance
- db_name: Name of the database for the RDS instance

These variables can be set in the terraform.tfvars file.# Use an official Node.js runtime as a parent image
FROM node:12

### Set the working directory to /app
WORKDIR /app

### Install any necessary dependencies
COPY package*.json ./
RUN npm install

### Copy the rest of the application code to the container
COPY . .

### Set environment variables
ENV DB_HOST=<your RDS host>
ENV DB_USER=<your RDS username>
ENV DB_PASSWORD=<your RDS password>
ENV DB_DATABASE=<your RDS database>

### Expose port 3000 for the application
EXPOSE 80

### Start the application
CMD ["npm", "start"]


### Docker Image build
- docker build -t your-image-name .
- docker run -p 3000:3000 your-image-name
- Creat AWS ECR
- docker tag my-repo:latest r.ecr.eu-west-3.amazonaws.com/my-repo:latest
- docker push.dkr.ecr.eu-west-3.amazonaws.com/my-repo:latest
- terraform apply

