# CHANGELOG

## TAHFA v0.3 (security)

- Fix open mail relay / sender spoofing: `_to` and `_from` are now server-side only
  by default; opt in with `allow_client_addresses`.
- Fix SSRF / local file read via `_reply_mail_template`: URLs must be https and on
  the `allowed_template_hosts` allowlist; redirects are refused.
- HTML-escape submitted fields in the notification mail body.
- Use `Template.safe_substitute` and stop leaking internal errors to callers.

## TAHFA v0.2

- New name: TAHFA
- New owner: wearetechnative
- Altcha challenge and validation
- Improved examples

## Terraform AWS HTML Form Action 0.1

- Initial publication
- Create Lambda entpoint
- Dependancy free Python code

