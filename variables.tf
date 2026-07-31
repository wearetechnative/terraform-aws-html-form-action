variable "name" {
  type = string
  description = "Name to use for function and api gateway"
}

variable "allowed_origin" {
  type = string
  description = "Which origin to allow submissions from. Use * when testing"
  default = "*"
}

variable "to_email" {
  type = string
  description = "'From' email to use when forwarding a message, defaults to recipient email in the Lambda, can also be configured in html form"
  default = ""
}

variable "from_email" {
  type = string
  description = "Receiving email address for forwarded messages, can also be configured in html form"
  default = ""
}

variable "allow_client_addresses" {
  type = bool
  description = "Allow the submitter to set the recipient (_to) and sender (_from) via hidden form fields. SECURITY: keep this false unless the form is fully trusted; enabling it turns the endpoint into an open mail relay."
  default = false
}

variable "allowed_template_hosts" {
  type = string
  description = "Comma-separated allowlist of hostnames that may serve reply-mail templates (_reply_mail_template). Leave empty to disable the reply-mail template feature. Only https URLs on these hosts are fetched; prevents SSRF / local file reads."
  default = ""
}

variable "use_altcha" {
  type = bool
  description = "Enable Altcha Spam protection"
}

variable "altcha_hmac_key" {
  type = string
  description = "HMAC Key to sign and validate Altcha Challenge"
  default = "change.me.now"
}
