FROM alpine:3.11 AS s6-alpine

# set version label
LABEL build_version="Alpine version-3.11 + S6 service"
LABEL maintainer="Tchube GitHub repository : https://github.com/Cocooning-tech/Dockerfile.git"

ARG S6_OVERLAY_RELEASE=https://github.com/just-containers/s6-overlay/releases/latest/download/s6-overlay-aarch64.tar$
ENV S6_OVERLAY_RELEASE=${S6_OVERLAY_RELEASE}

ADD rootfs /

# s6 overlay Download
ADD ${S6_OVERLAY_RELEASE} /tmp/s6overlay.tar.gz

# Build and some of image configuration
RUN apk upgrade --update --no-cache \
    && apk add --no-cache \
        bash \
        nano \
    && rm -rf /var/cache/apk/* \
    && tar xzf /tmp/s6overlay.tar.gz -C / \
    && rm /tmp/s6overlay.tar.gz

# Init
ENTRYPOINT [ "/init" ]
