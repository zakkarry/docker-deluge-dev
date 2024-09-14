# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/unrar:latest AS unrar

FROM ghcr.io/linuxserver/baseimage-alpine:edge

# environment variables
ENV PYTHON_EGG_CACHE="/config/plugins/.python-eggs" \
  TMPDIR=/run/deluged-temp

# copy release version script
COPY root/version.sh /app

# install software
RUN \
  echo "**** install build packages ****" && \
  apk add --no-cache --upgrade --virtual=build-dependencies \
    build-base \
    python3-dev \
    musl-dev \
    git \
    py3-cairo \
    py3-gobject3 && \
  echo "**** install packages ****" && \
  apk add --no-cache --upgrade \
    boost1.84-python3 \
    geoip \
    p7zip && \
  python3 -m venv /lsiopy && \
  pip install -U --no-cache-dir \
    pip \
    setuptools \
    wheel && \
  mkdir /app/deluge-src && \
  git clone https://github.com/deluge-torrent/deluge.git /app/deluge-src/ && \
  cd /app/deluge-src && \
  /bin/bash /app/version.sh > /app/deluge-src/RELEASE-VERSION && \
  sed -i "s|VERSION_FILE = os.path.join(os.path.dirname(__file__), 'RELEASE-VERSION')|VERSION_FILE = '/app/deluge-src/RELEASE-VERSION'|" /app/deluge-src/version.py && \
  sed -i '/version = call_git_describe(prefix, suffix)/s/version = call_git_describe(prefix, suffix)/version = release_version/' /app/deluge-src/version.py && \
  pip install /app/deluge-src && \
  pip install -U --no-cache-dir --find-links https://wheel-index.linuxserver.io/alpine-3.20/ \
    pygeoip && \
  echo "**** grab GeoIP database ****" && \
  curl -L --retry 10 --retry-max-time 60 --retry-all-errors \
    "https://mailfud.org/geoip-legacy/GeoIP.dat.gz" \
    | gunzip > /usr/share/GeoIP/GeoIP.dat && \
  printf "Linuxserver.io version: %s\nBuild-date: %s" "$(cat /app/deluge-src/RELEASE-VERSION)" "$(date +'%Y-%m-%d')" > /build_version && \
  echo "**** cleanup ****" && \
  apk del --purge \
    build-dependencies && \
  rm -rf \
   $HOME/.cache \
    /tmp/* \
    /app/*

# set build version and maintainer
LABEL build_version="LSIO-alpinebase (zakkarry) version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="zakkarry"

# add local files
COPY root/ /

# add unrar
COPY --from=unrar /usr/bin/unrar-alpine /usr/bin/unrar

# ports and volumes
EXPOSE 8112 58846 58946 58946/udp
VOLUME /config
