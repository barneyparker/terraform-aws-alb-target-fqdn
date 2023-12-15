resource "aws_cloudwatch_event_rule" "this" {
  name                = var.name
  description         = "${var.name} Scheduler"
  schedule_expression = var.cron_schedule
  state               = "ENABLED"
}

resource "aws_cloudwatch_event_target" "this" {
  target_id = var.name
  arn       = aws_lambda_function.this.arn
  rule      = aws_cloudwatch_event_rule.this.name
}

data "archive_file" "this" {
  type        = "zip"
  source_dir  = "${path.module}/source/"
  output_path = "${path.module}/.terraform/${var.name}.zip"
}

#tfsec:ignore:aws-lambda-enable-tracing
resource "aws_lambda_function" "this" {
  function_name    = var.name
  filename         = data.archive_file.this.output_path
  source_code_hash = data.archive_file.this.output_base64sha256
  role             = aws_iam_role.this.arn
  runtime          = "python3.9"
  handler          = "lambda.handler"
  architectures    = ["arm64"]
  memory_size      = 256
  timeout          = 300
  environment {
    variables = {
      FQDN_TAG = var.fqdn_tag
    }
  }
}

#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${aws_lambda_function.this.function_name}"
  retention_in_days = var.log_retention_in_days
}

resource "aws_iam_role" "this" {
  name = var.name

  assume_role_policy = data.aws_iam_policy_document.this_assume.json
  inline_policy {
    name   = "permissions"
    policy = data.aws_iam_policy_document.this.json
  }
  permissions_boundary = var.permission_boundary
}

data "aws_iam_policy_document" "this_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

#tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "this" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    #tfsec:ignore:aws-iam-no-policy-wildcards
    resources = ["*"]
  }

  statement {
    actions = [
      "elasticloadbalancing:DescribeTags",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:DescribeTargetHealth",
    ]
    resources = ["*"]
  }
}

resource "aws_lambda_permission" "this" {
  statement_id  = "ExecFromEvent"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.this.arn
}
