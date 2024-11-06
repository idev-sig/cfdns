FROM golang:alpine AS builder

WORKDIR /app

RUN apk add git curl

RUN git clone https://github.com/XIU2/CloudflareSpeedTest.git; \
    cd CloudflareSpeedTest; \
    go build

FROM alpine:latest
LABEL maintainer="Jetsung Chan<jetsungchan@gmail.com>"

WORKDIR /app

COPY --from=builder /app/CloudflareSpeedTest/CloudflareSpeedTest /usr/local/bin/CloudflareSpeedTest 
COPY --from=builder /app/CloudflareSpeedTest/ip.txt /app/ip.txt

CMD [ "CloudflareSpeedTest" ]