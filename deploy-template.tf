terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region                  = "us-east-1"
  profile                 = "default"
  shared_credentials_file = "./.env.terraform"
}

########################## VARS ##################################

variable "project" {
  type    = string
  default = "nomicol"
}

variable "environment" {
  type    = string
  default = "staging"
}

variable "default_sg_id" {
  type    = string
  default = "sg-ffb9d9d2"
}

########################## IMPORTING DEFAULR SG ##################################

data "aws_security_group" "default" {
  id = var.default_sg_id
}

########################## VPC CONFIGURATION ##################################

# Providing a reference to our default VPC
resource "aws_default_vpc" "default_vpc" {
}

# Providing a reference to our default subnets
data "aws_subnet_ids" "subnets" {
  vpc_id = aws_default_vpc.default_vpc.id
  depends_on = [
    aws_default_vpc.default_vpc
  ]
}

data "aws_subnet" "default" {
  for_each = data.aws_subnet_ids.subnets.ids
  id       = each.value
  depends_on = [
    data.aws_subnet_ids.subnets
  ]
}

########################## ECR CONFIGURATION ##################################

resource "aws_ecr_repository" "repo" {
  name = "${var.environment}-${var.project}-api"
}

########################## CLUSTER CONFIGURATION ##################################

resource "aws_ecs_cluster" "cluster" {
  name = "${var.environment}-${var.project}-api" # Naming the cluster
}

########################## LOG GROUP CONFIGURATION ##################################

resource "aws_cloudwatch_log_group" "log_group" {
  name = "${var.environment}-${var.project}"
  tags = {
    Environment = "staging"
    Application = "api"
  }
}

########################## TASK DEFINITION CONFIGURATION ##################################

resource "aws_ecs_task_definition" "task_defintion" {
  family                   = "${var.environment}-${var.project}-api-task" # Naming our first task
  container_definitions    = <<DEFINITION
  [
    {
      "name": "${var.environment}-${var.project}-api-task",
      "image": "${aws_ecr_repository.repo.repository_url}",
      "essential": true,
      "memory": 2048,
      "cpu": 1024,
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80,
          "protocol": "tcp"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${var.environment}-${var.project}",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "api"
        }
      },
      "environmentFiles": [
        {
          "value": "arn:aws:s3:::task-definition-env.${var.environment}.<domain>.com/.env",
          "type": "s3"
        }
      ]
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"] # Stating that we are using ECS Fargate
  network_mode             = "awsvpc"    # Using awsvpc as our network mode as this is required for Fargate
  memory                   = 2048        # Specifying the memory our container requires
  cpu                      = 1024        # Specifying the CPU our container requires
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
}

########################## IAM ROLE CONFIGURATION ##################################

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume-role-policy.json
}

data "aws_iam_policy_document" "assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

########################## APPLICATION LOAD BALANCER (ALB) CONFIGURATION ##################################

resource "aws_alb" "application_load_balancer" {
  name               = "${var.environment}-${var.project}-api-lb" # Naming our load balancer
  load_balancer_type = "application"
  security_groups    = ["${data.aws_security_group.default.id}"]
  subnets            = [for s in data.aws_subnet.default : s.id]
}

########################## TARGET GROUP (TG) CONFIGURATION ##################################

resource "aws_lb_target_group" "target_group" {
  name        = "${var.environment}-${var.project}-api-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_default_vpc.default_vpc.id # Referencing the default VPC
  health_check {
    matcher = "200,301,302"
    path    = "/v1/health"
  }
}

########################## LISTENERS CONFIGURATION ##################################

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_alb.application_load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_alb.application_load_balancer.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  certificate_arn   = "<ACM ARN>"


  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

########################## ECS SERVICE CONFIGURATION ##################################

resource "aws_ecs_service" "service" {
  name             = "${var.environment}-${var.project}-api-service" # Naming our first service
  cluster          = aws_ecs_cluster.cluster.id                      # Referencing our created Cluster
  task_definition  = aws_ecs_task_definition.task_defintion.arn      # Referencing the task our service will spin up
  launch_type      = "FARGATE"
  platform_version = "1.4.0"
  desired_count    = 1 # Setting the number of containers to 1

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn # Referencing our target group
    container_name   = aws_ecs_task_definition.task_defintion.family
    container_port   = 80 # Specifying the container port
  }

  network_configuration {
    assign_public_ip = true                                      # Providing our containers with public IPs
    security_groups  = ["${data.aws_security_group.default.id}"] # Setting the security group
    subnets          = [for s in data.aws_subnet.default : s.id]
  }
}
