module "lambda_function_formpost" {
  source = "terraform-aws-modules/lambda/aws"
  version = "3.3.1"

  function_name = "${var.name}-formpost"
  description   = "Sends mails at HTML Form submissions"
  handler       = "html_form_action.lambda_handler_form_post"
  runtime       = "python3.13"

  source_path = [
    format("%s/lambda_src", abspath(path.module)),
    {
      #pip_requirements = format("%s/lambda-src/requirements.txt", abspath(path.module))
    }
  ]

  publish = true
  timeout = 15

  environment_variables = {
    TO_MAIL = var.to_email
    FROM_MAIL = var.from_email
    ALTCHA_HMAC_KEY = var.altcha_hmac_key
    USE_ALTCHA = var.use_altcha
  }

  attach_policy_json = true
  policy_json = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": "ses:SendEmail",
      "Resource": "*"
    }
  ]
}
EOF

}

resource "aws_lambda_permission" "lambda_permission_formpost" {
  statement_id  = "AllowAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${var.name}-formpost"
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.formpost.execution_arn}/*/*"
}

resource "aws_api_gateway_rest_api" "formpost" {
  name = "${var.name}-formpost"
}

resource "aws_api_gateway_resource" "message_formpost" {
  rest_api_id = aws_api_gateway_rest_api.formpost.id
  parent_id = aws_api_gateway_rest_api.formpost.root_resource_id
  path_part = "message"
}

resource "aws_api_gateway_method" "message_formpost" {
  rest_api_id = aws_api_gateway_rest_api.formpost.id
  resource_id = aws_api_gateway_resource.message_formpost.id
  http_method = "POST"
  authorization = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_integration" "message_formpost" {
  rest_api_id = aws_api_gateway_rest_api.formpost.id
  resource_id = aws_api_gateway_resource.message_formpost.id
  http_method = "POST"
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = module.lambda_function_formpost.lambda_function_invoke_arn
  depends_on = [aws_api_gateway_method.message_formpost]
}

resource "aws_api_gateway_deployment" "formpost" {
  stage_name = "formpost"
  rest_api_id = aws_api_gateway_rest_api.formpost.id
  depends_on = [
    aws_api_gateway_integration.message_formpost,
  ]
}

module "resource_cors_formpost" {
  source  = "mewa/apigateway-cors/aws"
  version = "2.0.0"

  api      =  aws_api_gateway_rest_api.formpost.id
  resource =  aws_api_gateway_resource.message_formpost.id
  methods = ["POST"]

  origin = var.allowed_origin
}
