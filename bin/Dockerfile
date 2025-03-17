FROM condaforge/miniforge3:23.3.1-1

LABEL base.image="condaforge/miniforge3:23.3.1-1"
LABEL dockerfile.version="1"
LABEL software="ODHL_AR_Utilities"
LABEL description="ODHL_AR Utility Scripts"
LABEL maintainer="Michal Babinski"
LABEL maintainer2="Andrew Hale"
LABEL maintainer.email="michal.babinski@theiagen.com"
LABEL maintainer2.email="andrew.hale@theiagen.com"

ENV LC_ALL=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    ca-certificates \
    libmoo-perl \
    liblist-moreutils-perl \
    libjson-perl \
    gzip \
    file \
    build-essential \
    libbz2-dev \
    liblzma-dev \
    libncurses5-dev \
    python3-dev \
    python3-pip \
    libssl-dev \
    libreadline-dev \
    libsqlite3-dev \
    make \
    llvm \
    tk-dev \
    libffi-dev \
    bc \
    pigz \
    rsync \
    unzip \
    tar \
    curl \
    git \
    && apt-get autoclean \
    && rm -rf /var/lib/apt/lists/*

# Create and activate conda environment with specific Python version for Phoenix
RUN mamba create -y --name odhl-utils -c conda-forge -c bioconda -c defaults \
    python=3.7 \
    biopython \
    pandas \
    numpy \
    openpyxl \
    pyyaml \
    && conda clean -a

RUN pip install \
    glob2 \
    argparse \
    unidecode \
    regex \
    times \
    xlsxwriter \
    cryptography==36.0.2 \
    pytest-shutil

WORKDIR /data

RUN conda init bash
RUN echo "conda activate odhl-utils" >> ~/.bashrc

# Set up conda environment path
ENV CONDA_PREFIX=/opt/conda/envs/odhl-utils
ENV PATH=$CONDA_PREFIX/bin:$PATH

COPY . /odhl_ar_utils

CMD ["/bin/bash"]