# Steps
## Create docker image 

# Use an official Node.js runtime as a parent image
FROM node:12

# Set the working directory to /app
WORKDIR /app

# Install any necessary dependencies
COPY package*.json ./
RUN npm install

# Copy the rest of the application code to the container
COPY . .

# Set environment variables
ENV DB_HOST=<your RDS host>
ENV DB_USER=<your RDS username>
ENV DB_PASSWORD=<your RDS password>
ENV DB_DATABASE=<your RDS database>

# Expose port 3000 for the application
EXPOSE 80

# Start the application
CMD ["npm", "start"]


#
docker build -t your-image-name .
docker run -p 3000:3000 your-image-name
Creat AWS ECR
docker tag my-repo:latest r.ecr.eu-west-3.amazonaws.com/my-repo:latest
docker push.dkr.ecr.eu-west-3.amazonaws.com/my-repo:latest
terraform apply



