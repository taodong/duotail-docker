# duotail-docker
Docker images of duotail project

## Build Docker Image
Build the docker image with the following command:
```bash
cd images
./image-build.sh <product> [-t tag] [--mac] [--build-arg BUILD_ARG=value] [--build-arg BUILD_ARG2=value]
```
Examples:

**Build haraka image for mac**
```bash
# Build latest haraka image for mac
./image-build.sh haraka --mac
```

**Build postfix image for mac with domain `duotail.com`**
```bash
./image-build.sh postfix --mac --build-arg SMTP_DOMAIN=duotail.com
```