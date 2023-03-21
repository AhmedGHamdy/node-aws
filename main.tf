
  # Define the AWS provider and region and credentials 
    provider "aws" {
    region = "eu-west-3"
    //shared_config_files      = ["%USERPROFILE%/aws/conf"]
    //shared_credentials_files = [".aws/credentials"]
   
}



# Create a VPC with a private subnet and an internet gateway
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "my-vpc"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private-subnet"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "internet-gateway"
  }
}

# Create a security group for the RDS instance
resource "aws_security_group" "rds_security_group" {
  name_prefix = "rds-"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    security_groups = [aws_security_group.ecs_security_group.id]
  }

  tags = {
    Name = "rds-security-group"
  }
}

# Create a security group for the ECS service
resource "aws_security_group" "ecs_security_group" {
  name_prefix = "ecs-"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs-security-group"
  }
}

# Create an RDS instance in the private subnet
resource "aws_db_instance" "rds_instance" {
  identifier = "my-rds-instance"
  engine = "mysql"
  engine_version = "5.7"
  instance_class = "db.t2.micro"
  allocated_storage = 10
  storage_type = "gp2"
  db_subnet_group_name = "my-db-subnet-group"
  vpc_security_group_ids = [aws_security_group.rds_security_group.id]

  tags = {
    Name = "rds-instance"
  }
}

# Create an ECS Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "ecs-cluster"
}

# Create an ECS task definition for the Node.js application
resource "aws_ecs_task_definition" "task_definition" {
  family = "my-task"
  network_mode = "awsvpc"
  cpu = "256"
  memory = "512"

  container_definitions = jsonencode([
    {
      name = "my-container"
      image = "your-docker-image-url"
      portMappings = [
        {
          containerPort = 3000
          hostPort = 0
          protocol = "tcp"
        }
      ],
      environment = [
        {
          name = "DB_HOST"
          value = aws_db_instance.rds_instance.address
        },
        {
          name = "DB_USER"
          value = "your-db-username"
        },
        {
          name = "DB_PASSWORD"
          value = "your-db-password"
        },
        {
          name = "DB_DATABASE"
          value = "your-db-name"
        }
      ]
    }
  ])

  tags = {
    Name = "ecs-task-definition"
  }
}


# Create an ECS service to run the task definition
resource "aws_ecs_service" "ecs_service" {
  name = "my-ecs-service"
  cluster = aws_ecs_cluster.ecs_cluster.arn
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count = 3
  launch_type = "FARGATE"
  network_configuration {
    security_groups = [aws_security_group.ecs_security_group.id]
    subnets = [aws_subnet.private_subnet.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_alb_target_group.target_group.arn
    container_name   = "my-container"
    container_port   = 80
  }
  tags = {
    Name = "ecs-service"
  }
}



resource "aws_security_group" "lb_sg" {
  name_prefix = "lb_sg-"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lb_sg"
  }
}


resource "aws_security_group_rule" "lb_ingress" {
  cidr_blocks = ["192.0.2.0/24"]
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  security_group_id = aws_security_group.lb_sg.id

  depends_on = [aws_security_group.lb_sg]
}


resource "aws_lb" "load_balancer" {
  name               = "my-load-balancer"
  internal           = false
  load_balancer_type = "application"

  subnets            = aws_subnet.private.*.id
  security_groups    = [aws_security_group.lb_sg.id]

  depends_on         = [aws_security_group_rule.lb_ingress]
}



resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.target_group.arn
    type             = "forward"
  }
}

resource "aws_alb_target_group" "target_group" {
  name        = "my-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id

  health_check {
    healthy_threshold   = 2
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
}


# Create a CloudFront distribution
resource "aws_cloudfront_distribution" "distribution" {
  enabled = true

  origin {
    domain_name = aws_lb.load_balancer.dns_name
    origin_id   = aws_lb.load_balancer.dns_name

    custom_origin_config {
      http_port             = 80
      https_port            = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols  = ["TLSv1.2", "TLSv1.1", "TLSv1"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["HEAD", "GET"]
    cached_methods   = ["HEAD", "GET"]
    target_origin_id = aws_lb.load_balancer.dns_name

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
