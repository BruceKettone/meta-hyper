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
      qemu-system-arm \
      sudo

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

# Create the automated bootstrap script
RUN cat << 'EOF' > /home/yoctouser/bootstrap.sh
#!/bin/bash
cd /home/yoctouser/workspace

# Check if poky exists; if not, this is a fresh run and we must clone everything
if [ ! -d "poky" ]; then
    echo "=== Initializing Yocto Workspace Repositories (master branch) ==="

    # Pulling the rolling master branches to match your host
    git clone -b master git://git.yoctoproject.org/poky
    git clone -b master git://git.openembedded.org/meta-openembedded
    git clone -b master git://git.yoctoproject.org/meta-virtualization
    git clone -b master git://git.yoctoproject.org/meta-selinux

    # Pull your custom project layer
    echo "=== Pulling Custom meta-hyper Layer ==="
    git clone https://github.com/BruceKettone/meta-hyper.git custom-repo
fi

# Initialize the build environment
source poky/oe-init-build-env build > /dev/null

# If our custom layers aren't in bblayers.conf, inject them
if ! grep -q "meta-virtualization" conf/bblayers.conf; then
    echo "=== Configuring bblayers.conf ==="

    # Core OpenEmbedded Layers
    bitbake-layers add ../meta-openembedded/meta-oe
    bitbake-layers add ../meta-openembedded/meta-python
    bitbake-layers add ../meta-openembedded/meta-networking
    bitbake-layers add ../meta-openembedded/meta-filesystems
    bitbake-layers add ../meta-openembedded/meta-webserver

    # Security and Virtualization Layers
    bitbake-layers add ../meta-selinux
    bitbake-layers add ../meta-virtualization

    # Your custom layer (adjust path if your repo structure is different)
    bitbake-layers add ../custom-repo/meta-hyper/layers
fi

echo "=== Yocto Environment Ready ==="
echo "You can now run your bitbake commands."

# Replace the bootstrap script process with an interactive bash shell
exec /bin/bash
EOF

RUN chmod +x /home/yoctouser/bootstrap.sh
RUN mkdir workspace && chown yoctouser:yoctouser workspace

# Set the entrypoint so the bootstrap script runs automatically
ENTRYPOINT ["/home/yoctouser/bootstrap.sh"]
