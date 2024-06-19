
FROM alpine:latest

COPY ./scripts/daily/* /etc/periodic/daily

RUN apk update && \
    apk upgrade && \
    apk add --no-cache mariadb-client && \
    chmod a+x /etc/periodic/daily/*

RUN apk add --no-cache python3 py-pip
RUN pip install --no-cache-dir s3cmd && mkdir /s3