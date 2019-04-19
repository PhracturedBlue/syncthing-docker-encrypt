FROM golang:1.8 AS build-env
RUN printf "deb http://archive.debian.org/debian/ jessie main\ndeb-src http://archive.debian.org/debian/ jessie main\ndeb http://security.debian.org jessie/updates main\ndeb-src http://security.debian.org jessie/updates main" > /etc/apt/sources.list

RUN apt-get update && apt-get install -y fuse curl && rm -rf /var/lib/apt/lists/*
RUN \
echo "**** fetch syncthing code ****" && \
 ARCH=$(dpkg --print-architecture) && \
 if [ -z ${SYNCTHING_RELEASE+x} ]; then \
	SYNCTHING_RELEASE=$(curl -sX GET "https://api.github.com/repos/syncthing/syncthing/releases/latest" \
	| awk '/tag_name/{print $4;exit}' FS='[""]'); \
 fi && \
 curl -L -o /tmp/syncthing.tgz \
    https://github.com/syncthing/syncthing/releases/download/${SYNCTHING_RELEASE}/syncthing-linux-${ARCH}-${SYNCTHING_RELEASE}.tar.gz && \
 cd /tmp && tar -xf syncthing.tgz && \
 mv /tmp/syncthing-linux-${ARCH}-${SYNCTHING_RELEASE}/syncthing /
RUN \
echo "**** fetch gocryptfs code ****" && \
 ARCH=$(dpkg --print-architecture) && \
 if [ -z ${GOCRYPTFS_RELEASE+x} ]; then \
	GOCRYPTFS_RELEASE=$(curl -sX GET "https://api.github.com/repos/rfjakob/gocryptfs/releases/latest" \
	| awk '/tag_name/{print $4;exit}' FS='[""]'); \
 fi && \
 curl -L -o /tmp/gocryptfs.tgz \
    https://github.com/rfjakob/gocryptfs/releases/download/${GOCRYPTFS_RELEASE}/gocryptfs_${GOCRYPTFS_RELEASE}_linux-static_${ARCH}.tar.gz && \
 cd /tmp && tar -xf gocryptfs.tgz && \
 mv /tmp/gocryptfs /

ADD launcher.c /tmp/launcher.c
ADD keyfile.h /tmp/keyfile.h
RUN \
echo "**** building launcher ****" && \
 cd /tmp && gcc -static -o /launcher launcher.c && strip launcher

FROM gcr.io/distroless/base
EXPOSE 8384 22000 21027/udp
VOLUME ["/var/syncthing"]
VOLUME ["/var/crypt"]
COPY --from=build-env /bin/fusermount /bin/fusermount
COPY --from=build-env /syncthing /
COPY --from=build-env /gocryptfs /
COPY --from=build-env /launcher /

ENV HOME=/
ENTRYPOINT ["/launcher"]
