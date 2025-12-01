data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "archive_file" "microservice_chat_bot_archive_file" {
  type        = "zip"
  source_file = "${path.module}/lambda/lambda_function.py"
  output_path = "${path.module}/lambda/function.zip"
}

resource "aws_iam_role" "microservice_chat_bot_lambda_role" {
  name               = "microservice_chat_bot_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "microservice_chat_bot_lambda_basic_exec" {
  role       = aws_iam_role.microservice_chat_bot_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "microservice_chat_bot_lambda" {
  filename         = data.archive_file.microservice_chat_bot_archive_file.output_path
  function_name    = "microservice_chat_bot_lambda"
  role             = aws_iam_role.microservice_chat_bot_lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.microservice_chat_bot_archive_file.output_base64sha256

  runtime = var.python_version
  environment {
    variables = {
      environment = var.environment
      testapi     = var.groq_api
    }
  }

  memory_size = var.lambda_initial_spec["memory_size"]
  timeout     = var.lambda_initial_spec["timeout"]
  ephemeral_storage {
    size = var.lambda_initial_spec["ephemeral_storage"]["size"]
  }

  tags = merge(local.common_tags, {
    description = "sending user prompt to groq ai"
  })
}