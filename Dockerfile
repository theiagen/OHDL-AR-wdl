FROM condaforge/miniforge3:23.3.1-1

ARG MLST_VER=2.23.0
ARG ANY2FASTA_VER=0.4.2
ARG SAMTOOLSVER=1.16.1
ARG SAMBAMBAVER=0.8.2
ARG BBTOOLSVER=39.01
ARG PHX_VER=2.0.0

LABEL base.image="condaforge/miniforge3:23.3.1-1"
LABEL dockerfile.version="1"
LABEL software="ODHL_AR"
LABEL description="ODHL_AR Pipeline"
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
    ncbi-blast+ \
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
RUN mamba create -y --name odhl -c conda-forge -c bioconda -c defaults \
    python=3.7 \
    biopython \
    pandas \
    numpy \
    openpyxl \
    pyyaml \
    && conda clean -a

# Install additional Python packages for Phoenix
SHELL ["conda", "run", "-n", "odhl", "/bin/bash", "-c"]

# Install fastqc first (usually has fewer dependencies)
RUN mamba install -y -c bioconda fastqc=0.12.1 && conda clean -a

# Install fastani
RUN mamba install -y -c bioconda fastani=1.34 && conda clean -a

# Install SPAdes with more flexible versioning
RUN mamba install -y -c bioconda spades=3.15 && conda clean -a

# Try AMRFinderPlus with a more flexible version
RUN mamba install -y -c bioconda ncbi-amrfinderplus && conda clean -a

# Install remaining tools
RUN mamba install -y -c bioconda -c conda-forge \
    kraken2 \
    prokka \
    quast \
    && conda clean -a

RUN pip install \
    glob2 \
    argparse \
    unidecode \
    regex \
    times \
    xlsxwriter \
    cryptography==36.0.2 \
    pytest-shutil \
    pyre2

# Install any2fasta
RUN wget https://github.com/tseemann/any2fasta/archive/refs/tags/v${ANY2FASTA_VER}.tar.gz \
    && tar xzf v${ANY2FASTA_VER}.tar.gz \
    && rm v${ANY2FASTA_VER}.tar.gz \
    && chmod +x any2fasta-${ANY2FASTA_VER}/any2fasta \
    && mv -v any2fasta-${ANY2FASTA_VER}/any2fasta /usr/local/bin

# Install MLST and set up database
RUN wget https://github.com/tseemann/mlst/archive/v${MLST_VER}.tar.gz && \
    tar -xzf v${MLST_VER}.tar.gz && \
    rm v${MLST_VER}.tar.gz && \
    cd /mlst-${MLST_VER} && \
    wget -O - https://github.com/tseemann/mlst/archive/v${MLST_VER}.tar.gz | \
    tar xzf - --strip-components=2 mlst-${MLST_VER}/db && \
    chmod 755 --recursive db/*

# Add MLST to PATH
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/mlst-${MLST_VER}/bin:${PATH}"

RUN wget --progress=dot:giga https://github.com/samtools/samtools/releases/download/${SAMTOOLSVER}/samtools-${SAMTOOLSVER}.tar.bz2 && \
    tar -xjf samtools-${SAMTOOLSVER}.tar.bz2 && \
    rm samtools-${SAMTOOLSVER}.tar.bz2

WORKDIR /opt/samtools-${SAMTOOLSVER}
RUN ./configure && \
    make && \
    make install
WORKDIR /opt

# Download and install sambamba
RUN wget --progress=dot:giga https://github.com/biod/sambamba/releases/download/v${SAMBAMBAVER}/sambamba-${SAMBAMBAVER}-linux-amd64-static.gz && \
    gzip -d sambamba-${SAMBAMBAVER}-linux-amd64-static.gz && \
    mv /opt/sambamba-${SAMBAMBAVER}-linux-amd64-static /opt/sambamba && \
    chmod +x /opt/sambamba && \
    ln -s /opt/sambamba /usr/local/bin

# Download and install bbtools
RUN wget --progress=dot:giga https://sourceforge.net/projects/bbmap/files/BBMap_${BBTOOLSVER}.tar.gz && \
    tar -xzf BBMap_${BBTOOLSVER}.tar.gz && \
    rm BBMap_${BBTOOLSVER}.tar.gz && \
    ln -s /opt/bbmap/*.sh /usr/local/bin/

RUN conda init bash
RUN echo "conda activate odhl" >> ~/.bashrc

# Set up conda environment path
ENV CONDA_PREFIX=/opt/conda/envs/odhl
ENV PATH=$CONDA_PREFIX/bin:$PATH

COPY . /ODHL_AR

RUN chmod +x /ODHL_AR/main.nf

WORKDIR /data

CMD ["/bin/bash"]