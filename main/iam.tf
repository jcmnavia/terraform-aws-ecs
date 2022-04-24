########################## IAM ROLE CONFIGURATION ##################################

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "${var.project}-ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.assume-role-policy.json
  tags = {
    Name        = "${var.project}-iam-role"
    Environment = "${var.environment}"
  }
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
