# Get latest version of Ubuntu
FROM ubuntu:24.10

# Install packages without interaction
ENV DEBIAN_FRONTEND=noninteractive

# Install your OS dependencies
RUN apt update && apt install -y build-essential r-base python3 python3-pip python3-setuptools python3-dev checkinstall wget curl

# Set your working directory
WORKDIR /swish

# COPY requirements.txt /swish/requirements.txt

# RUN pip3 install -r requirements.txt

# Package to work with tabular data
RUN Rscript -e "install.packages('data.table')"

# Download python 2.7.x source code
RUN wget https://www.python.org/ftp/python/2.7.18/Python-2.7.18.tgz

# Unpack python 2.7.x source
RUN tar -xvf Python-2.7.18.tgz

# Change dirs and build python 2.7.x
RUN cd Python-2.7.18 && ./configure --enable-optimizations && make && make install

# COPY . /swish