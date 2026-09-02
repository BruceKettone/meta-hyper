FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

RUN \
    apt-get update && \
    apt-get install -y \
      build-essential \
      chrpath \
      cpio \
      debianutils \
      diffstat \
      file \
      gawk \
      gcc \
      git \
      iputils-ping \
      libacl1 \
      locales \
      python3 \
      python3-git \
      python3-jinja2 \
      python3-pexpect \
      python3-pip \
      python3-subunit \
      socat \
      texinfo \
      unzip \
      wget \
      xz-utils \
      zstd \
      neovim \
      sudo \
      tmux \
      qemu-system-arm

RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen

ENV LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en

RUN useradd -m -s /bin/bash yoctouser && \
    usermod -aG sudo yoctouser && \
    echo "yoctouser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER yoctouser

WORKDIR /home/yoctouser
RUN mkdir -p workspace/layers && \
    chown -R yoctouser:yoctouser workspace
RUN git clone https://git.openembedded.org/bitbake && \
    ./bitbake/bin/bitbake-setup settings set --global default top-dir-prefix /home/yoctouser/workspace

# Clone the missing external dependencies directly into the workspace
WORKDIR /home/yoctouser/workspace/layers

# 1. Clone all required Yocto repositories (master branch) into the layers directory
RUN git clone -b master git://git.yoctoproject.org/poky && \
    git clone -b master git://git.openembedded.org/meta-openembedded && \
    git clone -b master git://git.yoctoproject.org/meta-virtualization && \
    git clone https://github.com/BruceKettone/meta-hyper.git meta-hyper

# 2. Initialize the build environment and configure bblayers.conf non-interactively
WORKDIR /home/yoctouser/workspace
RUN bash -c "source layers/poky/oe-init-build-env build && \
    bitbake-layers add ../layers/meta-openembedded/meta-oe && \
    bitbake-layers add ../layers/meta-openembedded/meta-python && \
    bitbake-layers add ../layers/meta-openembedded/meta-networking && \
    bitbake-layers add ../layers/meta-openembedded/meta-filesystems && \
    bitbake-layers add ../layers/meta-openembedded/meta-webserver && \
    bitbake-layers add ../layers/meta-virtualization && \
    bitbake-layers add ../layers/meta-hyper"

# Reset workdir to the user's home
WORKDIR /home/yoctouser
