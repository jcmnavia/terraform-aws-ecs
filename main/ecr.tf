########################## ECR CONFIGURATION ##################################

resource "aws_ecr_repository" "repo" {
  name = "${var.project}-${var.environment}-ecr"
  tags = {
    Name        = "${var.project}-ecr"
    Environment = "${var.environment}"
  }
}
