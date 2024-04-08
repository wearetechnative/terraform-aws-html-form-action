module "form_action_example_com" {
  source         = "wearetechnative/html-form-action/aws"

  name           = "example-com-form-action-handler"
  allowed_origin = "*" # You should set this to the website url when live
}

output "example_com_form_action_url_for_form" {
  description = "Place this URL in your the action attribute of your form element."
  value = module.form_action_example_com.message_post_url
}
