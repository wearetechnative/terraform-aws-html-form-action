module "lambda_function_altchachallenge" {
  source = "terraform-aws-modules/lambda/aws"
  version = "3.3.1"

  function_name = "${var.name}-altcha"
  description   = "Creates altcha_challenge"
  handler       = "html_form_action.lambda_handler_altcha_challenge"
  runtime       = "python3.9"

  source_path = [
    format("%s/lambda_src", abspath(path.module)),
    {
      #pip_requirements = format("%s/lambda-src/requirements.txt", abspath(path.module))
    }
  ]

  publish = true
  timeout = 15

  environment_variables = {
    ALTCHA_HMAC_KEY = var.altcha_hmac_key
  }
}

resource "aws_lambda_permission" "lambda_permission" {
  statement_id  = "AllowAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${var.name}-altcha"
  principal     = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.altcha_challenge.execution_arn}/*/*"
}

resource "aws_api_gateway_rest_api" "altcha_challenge" {
  name = "${var.name}-altcha"
}

resource "aws_api_gateway_resource" "message_altchachallenge" {
  rest_api_id = aws_api_gateway_rest_api.altcha_challenge.id
  parent_id = aws_api_gateway_rest_api.altcha_challenge.root_resource_id
  path_part = "message"
}

resource "aws_api_gateway_method" "message_altchachallenge" {
  rest_api_id = aws_api_gateway_rest_api.altcha_challenge.id
  resource_id = aws_api_gateway_resource.message_altchachallenge.id
  http_method = "GET"
  authorization = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_integration" "message_altchachallenge" {
  rest_api_id = aws_api_gateway_rest_api.altcha_challenge.id
  resource_id = aws_api_gateway_resource.message_altchachallenge.id
  http_method = "GET"
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = module.lambda_function_altchachallenge.lambda_function_invoke_arn
  depends_on = [aws_api_gateway_method.message_altchachallenge]
}

resource "aws_api_gateway_deployment" "altcha_challenge" {
  stage_name = "altcha_challenge"
  rest_api_id = aws_api_gateway_rest_api.altcha_challenge.id
  depends_on = [
    aws_api_gateway_integration.message_altchachallenge,
  ]
}

module "resource_cors_altchachallenge" {
  source  = "mewa/apigateway-cors/aws"
  version = "2.0.0"

  api      =  aws_api_gateway_rest_api.altcha_challenge.id
  resource =  aws_api_gateway_resource.message_altchachallenge.id
  methods = ["GET"]

  origin = var.allowed_origin
}
