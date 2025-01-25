FROM golang:alpine AS builder

WORKDIR /app

RUN apk add git curl

RUN git clone https://github.com/XIU2/CloudflareSpeedTest.git; \
    cd CloudflareSpeedTest; \
    go build

FROM alpine:latest
LABEL maintainer="Jetsung Chan<i@jetsung.com>"

WORKDIR /app

RUN apk add --no-cache curl bash jq

COPY --from=builder /app/CloudflareSpeedTest/CloudflareSpeedTest /usr/local/bin/CloudflareSpeedTest 
COPY --from=builder /app/CloudflareSpeedTest/ip.txt /app/ip.txt
COPY --from=builder /app/CloudflareSpeedTest/scripts/cfspeedtest.sh /usr/local/bin/cfspeedtest
COPY --from=builder /app/CloudflareSpeedTest/scripts/cfdns.sh /usr/local/bin/cfdns

RUN chmod +x /usr/local/bin/cfspeedtest
RUN chmod +x /usr/local/bin/cfdns

CMD [ "cfspeedtest" "-h" ]
