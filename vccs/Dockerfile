FROM docker.sunet.se/eduid/fastapi:20260116T091550-staging

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
    apt-get -y dist-upgrade && \
    apt-get install -y \
    softhsm2 \
    opensc \
    openssl
