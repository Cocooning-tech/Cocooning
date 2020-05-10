# FROM lsiobase/alpine:arm64v8-3.11
FROM cocooning/alpine:arm64v8

# set version label
ARG BUILD_DATE
ARG VERSION
ARG DDCLIENT_VERSION
# set version label
LABEL build_version="ddclient-3.9.1"
LABEL maintainer="Tchube GitHub repository : https://github.com/Cocooning-tech/Dockerfile.git"


# copy local files
COPY root/ /

RUN \
 echo "**** install build packages ****" && \
 apk add --no-cache --virtual=build-dependencies \
	bzip2 \
	gcc \
	make \
	tar \
	wget && \
 echo "**** install runtime packages ****" && \
 apk add --no-cache \
	curl \
	inotify-tools \
	jq \
	perl \
	perl-digest-sha1 \
	perl-io-socket-inet6 \
	perl-io-socket-ssl \
	perl-json && \
 echo "***** install perl modules ****" && \
 curl -L http://cpanmin.us | perl - App::cpanminus && \
 cpanm \
	Data::Validate::IP \
	JSON::Any && \
 echo "**** modifier permissions ddclient ****" && \
 chmod +x /usr/bin/ddclient && \
 echo "**** cleanup ****" && \
 apk del --purge \
	build-dependencies && \
 rm -rf \
	/config/.cpanm \
	/root/.cpanm \
	/tmp/*

# ports and volumes
VOLUME /config
