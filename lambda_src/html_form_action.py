import boto3
from botocore.exceptions import ClientError
import json
import os
import re
import urllib.parse
import urllib
import urllib.request
from string import Template

#import uuid
from random import randrange
import hashlib
import hmac


def field_value(field_dict, key, default):
    if key in field_dict:
        return field_dict[key][0]
    else:
        return default

def flatten_fields(fields):
    new_fields = {}
    for key, value in fields.items():
        if type(value) == list:
            new_fields[key] = value[0]

    return new_fields


def form_mail_body(field_dict):
    html = ""
    for key, value in field_dict.items():
        if key[0] == "_":
            continue

        html += "<p><strong>"+key+":</strong><br>"
        html += value[0]+"</p>"

    return html

def get_template(link):
    f = urllib.request.urlopen(link)
    template = f.read()
    return template.decode("utf-8")

def send_reply_mail(fields):

    if "_reply_mail_template" in fields and "_visiter_email_field" in fields and fields["_visiter_email_field"][0] in fields:
        to_address = fields[fields["_visiter_email_field"][0]][0]
        if re.match(r"[^@]+@[^@]+\.[^@]+", to_address):

            mail_template = str(get_template(fields["_reply_mail_template"][0]))
            src = Template(mail_template)
            mail_body = src.substitute(flatten_fields(fields))

            match = re.search('<title>(.*?)</title>', mail_body)
            subject = match.group(1) if match else 'No subject'

            from_address = field_value(fields, "_from", os.environ.get('FROM_MAIL'))

            raw_send(to_address, from_address, subject, mail_body)

def send_form_mail(fields):
    field_html = form_mail_body(fields)
    mail_body = f" <html> <head></head> <body> <h1>Form data</h1>{field_html} </body> </html> "
    to_address = field_value(fields, "_to", os.environ.get('TO_MAIL'))
    from_address = field_value(fields, "_from", os.environ.get('FROM_MAIL'))
    subject = field_value(fields,"_subject", "Form Submission")

    raw_send(to_address, from_address, subject, mail_body)

def raw_send(to_address, from_address, subject, mail_body):

    mail_charset = "UTF-8"
    AWS_REGION   = "eu-central-1" # TODO ENVVAR
    client = boto3.client('ses',region_name=AWS_REGION)

    response = client.send_email(
        Destination={
            'ToAddresses': [
                to_address,
            ],
        },
        Message={
            'Body': {
                'Html': {
                    'Charset': mail_charset,
                    'Data': mail_body,
                },
            },
            'Subject': {
                'Charset': mail_charset,
                'Data': subject,
            },
        },
        Source=from_address,
    )

def lambda_handler_form_post(event, lambda_context):

    #slack_webhook_url = os.environ.get('SLACK_WEBHOOK_URL')
    #lambda_conf = json.loads(os.environ.get('LAMBDA_CONF'))
    #sts_master_account_role_arn = os.environ.get('STS_MASTER_ACCOUNT_ROLE_ARN')
    #default_threshold = os.environ.get('DEFAULT_THRESHOLD')

    queryStr = event["body"]
    fields = urllib.parse.parse_qs(queryStr)


    success_url = field_value(fields, "_success_url", "")
    return_body="<html> <head> </head> <body> Form has been submitted.  </body> </html>"
    if(success_url != ""):
        return_body=f"<html><head><meta http-equiv=\"Refresh\" content=\"0; URL={success_url}\" /></head><body></body></html>"

    try:
        send_form_mail(fields)
        send_reply_mail(fields)

    except ClientError as e:
        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "text/html"
                },
            "body": "<h1>FAIL</h1>" + e.response['Error']['Message']
            }

    else:
        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "text/html"
                },
            "body": return_body
            #"body": json.dumps(event)
            }

def createHash(salt, number):
    hasher = hashlib.sha256()
    hasher.update((salt + str(number)).encode('utf-8'))
    hash_value = hasher.digest()
    return hash_value.hex()

def createHmac(secret_key, challenge):
    hash_algorithm = 'sha256'
    hmac_object = hmac.new(secret_key.encode(), challenge.encode(), getattr(hashlib, hash_algorithm))
    return hmac_object.hexdigest()

def lambda_handler_altcha_challenge(event, lambda_context):

    salt = os.urandom(12).hex()
    secret_number = randrange(10000, 100000, 1)
    print(secret_number)
    hmac_secret = os.environ.get('ALTCHA_HMAC_KEY')

    challenge = createHash(salt, secret_number)
    signature = createHmac(hmac_secret, challenge)

    ch = {}
    ch["algorithm"] = "SHA-256"
    ch["challenge"] = challenge
    ch["salt"] = salt
    ch["signature"] = signature

    return_body = json.dumps(ch)

    return {
        "statusCode": 200,
        "headers": {
            "Access-Control-Allow-Origin": "*",
            "Content-Type": "application/json"
            },
        "body": return_body
    }


## THIS BLOCK IS TOO RUN LAMBDA LOCALLY
if __name__ == '__main__':
    mock_event = {
            "body": "_reply_mail_template=https://technative.eu/_mail/demo-template/&_visiter_email_field=Email&_subject=Demo+Form+Submission&_to=pim%40technative.nl&_from=pim%40technative.nl&_success_url=http%3A%2F%2Flocalhost%3A8000%2Fform_success.html&_fail_url=http%3A%2F%2Flocalhost%3A8000%2Fform.html&full-name=test&Email=pim@technative.eu&message=test"
            }

    #lambda_handler_form_post(mock_event, {})
    print(lambda_handler_altcha_challenge({}, {}))




