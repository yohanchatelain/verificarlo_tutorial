# Dockerfile for Verificarlo Tutorial
# Based on the setup from tutorial.ipynb

FROM ubuntu:24.04

# Set environment variables
ARG LLVM_VERSION=20
ENV LLVM_VERSION=${LLVM_VERSION}
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install -y -qq \
    autoconf \
    automake \
    libtool \
    build-essential \
    libmpfr-dev \
    python3-dev \
    python3-pip \
    git \
    parallel \
    wget \
    lsb-release \
    software-properties-common \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Install LLVM and Clang (Verificarlo 2.5+ requires LLVM 17-21)
RUN apt-get install -y -qq \
    llvm-${LLVM_VERSION} \
    llvm-${LLVM_VERSION}-dev \
    clang-${LLVM_VERSION} \
    libclang-rt-${LLVM_VERSION}-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages
RUN pip install -q numpy scipy pandas significantdigits matplotlib

# Clone and build Verificarlo
RUN git clone --depth 1 https://github.com/verificarlo/verificarlo.git /tmp/verificarlo && \
    cd /tmp/verificarlo && \
    ./autogen.sh > /dev/null 2>&1 && \
    ./configure --with-llvm=$(llvm-config-${LLVM_VERSION} --prefix) --without-flang --without-prism > /dev/null 2>&1 && \
    make install-interflop-stdlib > /dev/null 2>&1 && \
    make -j$(nproc) > /dev/null 2>&1 && \
    make install > /dev/null 2>&1 && \
    cd / && \
    rm -rf /tmp/verificarlo

# Set up working directory
WORKDIR /workspace

# Copy tutorial files
COPY . /workspace

# Add /usr/local/bin to PATH (where verificarlo is installed)
ENV PATH="/usr/local/bin:${PATH}"

# Verify installation
RUN verificarlo-c --version

# Default command
CMD ["/bin/bash"]
