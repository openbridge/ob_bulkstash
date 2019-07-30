FROM alpine:3.9
MAINTAINER Thomas Spicer <thomas@openbridge.com>

ARG RCLONE_VERSION="current"
ENV RCLONE_TYPE="amd64"
ENV BUILD_DEPS \
      wget \
      linux-headers \
      unzip \
      fuse
RUN set -x \
    && apk update \
    && apk add --no-cache --virtual .persistent-deps \
       bash \
       curl \
       monit \
       tzdata \
       ca-certificates \
    && apk add --no-cache --virtual .build-deps \
        $BUILD_DEPS \
    && cd /tmp  \
    && wget -q http://downloads.rclone.org/v${RCLONE_VERSION}/rclone-v${RCLONE_VERSION}-linux-${RCLONE_TYPE}.zip \
    && unzip /tmp/rclone-v${RCLONE_VERSION}-linux-${RCLONE_TYPE}.zip \
    && mv /tmp/rclone-*-linux-${RCLONE_TYPE}/rclone /usr/bin \
    && addgroup -g 1000 rclone \
    && adduser -SDH -u 1000 -s /bin/false rclone -G rclone \
    && sed -i 's/#user_allow_other/user_allow_other/' /etc/fuse.conf \
	  && mkdir -p /config /defaults /data \
    && rm -Rf /tmp/* \
    && rm -rf /var/cache/apk/* \
    && apk del .build-deps

COPY monit.d/ /etc/monit.d/
COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY rclone.sh /rclone.sh
COPY rcron.sh /usr/bin/rcron
COPY env_secrets.sh /env_secrets.sh
RUN chmod +x /docker-entrypoint.sh /usr/bin/rcron

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD [""]
