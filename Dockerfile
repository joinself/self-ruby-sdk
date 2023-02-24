FROM ruby:3.2.1-slim-buster

RUN apt-get update && \
    apt-get install -y --no-install-recommends git cmake build-essential && \
    cd /tmp && \
    git clone https://github.com/google/flatbuffers.git && \
    cd /tmp/flatbuffers && \
    git checkout v2.0.0 && \
    cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release && \
    make install && \
    rm -rf /var/lib/apt/lists/* /tmp/*

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl libsodium-dev netbase && \
    curl https://download.joinself.com/olm/libself-olm_0.1.17_amd64.deb -o /tmp/libself-olm_0.1.17_amd64.deb && \
    curl https://download.joinself.com/omemo/libself-omemo_0.1.3_amd64.deb -o /tmp/libself-omemo_0.1.3_amd64.deb && \
    apt-get install -y --no-install-recommends /tmp/libself-olm_0.1.17_amd64.deb /tmp/libself-omemo_0.1.3_amd64.deb && \
    rm -rf /var/lib/apt/lists/* /tmp/*
