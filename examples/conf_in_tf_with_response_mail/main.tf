module "form_action_example_com" {
  source         = "wearetechnative/html-form-action/aws"

  name           = "example-com-form-action-handler"
  to_email       = "webinbox@example.com" # Make sure SES accepts this email address or complete domain
  from_email     = "no-reply@example.com" # Make sure SES accepts this email address or complete domain
}

output "example_com_form_action_url_for_form" {
  description = "Place this URL in your the action attribute of your form element."
  value = module.form_action_example_com.message_post_url
}
