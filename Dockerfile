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
    apt-get install -y --no-install-recommends curl netbase && \
    curl -Lo /tmp/self-omemo.deb https://github.com/joinself/self-omemo/releases/download/0.4.0/self-omemo_0.4.0_amd64.deb && \
    apt-get install -y --no-install-recommends /tmp/self-omemo.deb && \
    rm -rf /var/lib/apt/lists/* /tmp/*
