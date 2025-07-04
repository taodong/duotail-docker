# Image for doutail postfix server

## Notes
1. Default health check endpoint :8080/health.
2. Default domain is set to `example.com` which can be changed through `SMTP_DOMAIN` argument.
3. `example.com` is configured as local mail name.
4. Default SMTP port is set to 25.
5. Configured `test@example.com` as a test email address. The local mailbox is under `/var/spool/mail` directory.

## Environment Variables
The following environment variables need to be set in the container:
- `POSTFIX_USERNAME`: The username of the email used to sasl login the Postfix server.
- `POSTFIX_DOMAIN`: The domain name of the email to sasl login the Postfix server.
- `POSTFIX_PASSWORD`: The password of the email to sasl login the Postfix server.
- `DKIM_DOMAIN`: The domain name for DKIM signing when opendkim is enabled.
- `DKIM_SELECTOR`: The selector for DKIM signing when opendkim is enabled.