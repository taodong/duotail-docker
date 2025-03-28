FROM ubuntu:24.04

RUN apt-get update && \
    apt-get install -y kafkacat && \
    apt-get install -y curl

EXPOSE 8080

CMD ["tail", "-f", "/dev/null"]