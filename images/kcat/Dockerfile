FROM ubuntu:24.04

RUN apt-get update && \
    apt-get install -y kafkacat

EXPOSE 8080

CMD ["tail", "-f", "/dev/null"]