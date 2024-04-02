output "message_post_url" {
  value = "${aws_api_gateway_deployment.formpost.invoke_url}/message"
  description = "POST URL for message requests"
}

output "message_altcha_challenge_url" {
  value = "${aws_api_gateway_deployment.altcha_challenge.invoke_url}/message"
  description = "GET URL for Altcha Challenge requests"
}
