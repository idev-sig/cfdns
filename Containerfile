FROM golang:alpine AS builder

WORKDIR /app

RUN apk add git curl

RUN git clone https://github.com/XIU2/CloudflareSpeedTest.git; \
    cd CloudflareSpeedTest; \
    go build

FROM alpine:latest
LABEL maintainer="Jetsung Chan<i@jetsung.com>"

WORKDIR /app

RUN apk add --no-cache curl bash jq cronie

COPY --from=builder /app/CloudflareSpeedTest/CloudflareSpeedTest /usr/local/bin/CloudflareSpeedTest 
COPY --from=builder /app/CloudflareSpeedTest/ip.txt /app/ip.txt

COPY scripts/cfspeedtest.sh /usr/local/bin/cfspeedtest
COPY scripts/cfdns.sh /usr/local/bin/cfdns

RUN chmod +x /usr/local/bin/cfspeedtest
RUN chmod +x /usr/local/bin/cfdns

RUN mkdir ~/.cache

RUN printf "%b" '#!'"/usr/bin/env bash\n \
if [ \"\$1\" = \"daemon\" ];  then \n \
 exec crond -n -s -m off \n \
else \n \
 exec -- \"\$@\"\n \
fi\n" >/entry.sh && chmod +x /entry.sh

VOLUME /app

ENTRYPOINT ["/entry.sh"]

CMD ["--help"]
