########################## CLUSTER CONFIGURATION ##################################

resource "aws_ecs_cluster" "cluster" {
  name = "${var.project}-${var.environment}-cluster" # Naming the cluster
  tags = {
    Name        = "${var.project}-ecs"
    Environment = "${var.environment}"
  }
}


########################## LOG GROUP CONFIGURATION ##################################

resource "aws_cloudwatch_log_group" "log_group" {
  name = "${var.project}-${var.environment}-logs"
  tags = {
    Name        = "${var.project}-logs"
    Environment = "${var.environment}"
  }
}

########################## TASK DEFINITION CONFIGURATION ##################################

resource "aws_ecs_task_definition" "task_defintion" {
  family                   = "${var.project}-${var.environment}-task" # Naming our first task
  container_definitions    = <<DEFINITION
  [
    {
      "name": "${var.project}-${var.environment}-task",
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
          "awslogs-group": "${var.project}-${var.environment}-logs",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "api"
        }
      },
      "environmentFiles": [
        {
          "value": "${var.task-bucket}",
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

  tags = {
    Name        = "${var.project}-ecs-td"
    Environment = "${var.environment}"
  }
}

########################## ECS SERVICE CONFIGURATION ##################################

resource "aws_ecs_service" "service" {
  name             = "${var.project}-${var.environment}-ecs-service" # Naming our first service
  cluster          = aws_ecs_cluster.cluster.id                      # Referencing our created Cluster
  task_definition  = aws_ecs_task_definition.task_defintion.arn      # Referencing the task our service will spin up
  launch_type      = "FARGATE"
  platform_version = "1.4.0"
  desired_count    = 1 # Setting the number of containers to 1

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn          # Referencing our target group
    container_name   = aws_ecs_task_definition.task_defintion.family # Referencing out tasks containers
    container_port   = 80                                            # Specifying the container port
  }

  network_configuration {
    assign_public_ip = false
    security_groups  = [aws_security_group.ecs_sg.id]
    subnets          = aws_subnet.private.*.id
  }
}
