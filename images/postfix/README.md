# Image for doutail postfix server

## Notes
1. Default health check endpoint :8080/health.
2. Default domain is set to `example.com` which can be changed through `SMTP_DOMAIN` argument.
3. `example.com` is configured as local mail name.
4. Default SMTP port is set to 25.
5. Configured `test@example.com` as a test email address. The local mailbox is under `/var/spool/mail` directory.