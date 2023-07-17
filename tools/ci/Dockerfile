# syntax=docker/dockerfile:1
# This Dockerfile is used to build a "builder" image providing required tools
# in CI pipelines without polluting the global environment.

ARG DWARVES_INSTALL_VERSION=1.24

FROM openeuler/openeuler:23.03 AS pahole-build
ARG DWARVES_INSTALL_VERSION
RUN yum -y install \
    cmake \
    elfutils-devel \
    gcc \
    git \
    make \
    zlib-devel \
    && \
    yum clean all
RUN git clone --depth 1 --branch "v${DWARVES_INSTALL_VERSION}" --recurse-submodules \
        https://github.com/acmel/dwarves.git /dwarves && \
    mkdir -p /dwarves/build && \
    cd /dwarves/build && \
    cmake -D__LIB=lib -DBUILD_SHARED_LIBS=OFF .. && \
    make -j "$(nproc)" pahole

FROM openeuler/openeuler:23.03 AS builder
RUN yum -y install \
    bpftool \
    clang \
    findutils \
    git \
    go \
    jq \
    make \
    rsync \
    xz \
    && \
    yum clean all
COPY --from=pahole-build /dwarves/build/pahole /usr/local/bin/pahole
ENV GOPROXY=https://repo.huaweicloud.com/repository/goproxy/,direct
RUN printf '%s\n' > /usr/local/bin/btfhub-git-askpass.sh \
    "#!/usr/bin/env bash" \
    'case "$1" in' \
    'Username*)' \
    '   if [[ -n "$BTFHUB_GIT_USERNAME" ]]; then' \
    '       echo "$BTFHUB_GIT_USERNAME"' \
    '   else' \
    '       echo >&2 "BTFHUB_GIT_USERNAME not defined"; exit 1' \
    '   fi ;;' \
    'Password*)' \
    '   if [[ -n "$BTFHUB_GIT_PASSWORD" ]]; then' \
    '       echo "$BTFHUB_GIT_PASSWORD"' \
    '   else' \
    '       echo >&2 "BTFHUB_GIT_PASSWORD not defined"; exit 1' \
    '   fi ;;' \
    'esac' && \
    chmod +x /usr/local/bin/btfhub-git-askpass.sh
ENV GIT_ASKPASS=btfhub-git-askpass.sh
