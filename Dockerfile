# Use conda as base image
FROM condaforge/miniforge3:23.3.1-1

# Version and metadata labels
LABEL base.image="condaforge/miniforge3:23.3.1-1"
LABEL dockerfile.version="1"
LABEL software="ODHL_AR"
LABEL description="ODHL_AR Pipeline"
LABEL maintainer="Michal Babinski"
LABEL maintainer2="Andrew Hale"
LABEL maintainer.email="michal.babinski@theiagen.com"
LABEL maintainer2.email="andrew.hale@theiagen.com"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    bzip2 \
    ca-certificates \
    curl \
    git \
    procps \
    unzip \
    wget \
    apt-transport-https \
    gnupg-agent \
    software-properties-common && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://get.docker.com | sh

# Copy the ODHL_AR directory
COPY . /ODHL_AR

# Create conda environment
RUN mamba create -y --name odhl -c conda-forge -c bioconda -c defaults \
    python=3.9 \
    nextflow=24.10.4 \
    pandas \
    biopython \
    && mamba clean -a -y

# Activate conda env
RUN conda init bash
RUN echo "conda activate odhl" >> ~/.bashrc

# Set up conda environment path
ENV CONDA_PREFIX=/opt/conda/envs/odhl
ENV PATH=$CONDA_PREFIX/bin:$PATH

# Set utf-8 encoding
ENV LC_ALL=C.UTF-8

# Make the ODHL pipeline executable
RUN chmod +x /ODHL_AR/main.nf

# Set workdir
WORKDIR /ODHL_AR

SHELL ["/bin/bash", "-c"]