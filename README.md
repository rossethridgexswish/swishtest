# Build Notes
## Objective
Create an image with python2, python3, R, install a set of requirements and upload it to
docker hub.

## Disclaimer
Build times are based on my home machine which has 24 cores and 64GB RAM.  
Mileage may vary, depending on hardware.
```text
○ → lscpu
Architecture:             x86_64
  CPU op-mode(s):         32-bit, 64-bit
  Address sizes:          48 bits physical, 48 bits virtual
  Byte Order:             Little Endian
CPU(s):                   24


○ → free -m
               total        used        free      shared  buff/cache   available
Mem:           64204        8788       40353         797       15062       50424
Swap:          20479           0       20479
```

### My Dockerfile
```text
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

```

### My initial build time: 9m15.564s
```text
○ → time docker build . -t swishtest

Removing intermediate container 67cc9cfc6091
 ---> 394102a1c09f
Successfully built 394102a1c09f
Successfully tagged swishtest:latest

real	9m15.564s
user	0m0.040s
sys	0m0.156s
```

### Image result for 'swishtest':
```text
○ → docker image list
REPOSITORY   TAG       IMAGE ID       CREATED         SIZE
swishtest    latest    394102a1c09f   3 minutes ago   1.34GB
ubuntu       latest    35a88802559d   3 weeks ago     78.1MB
```

### Running the 'swishtest' container in daemon mode (detached)
```text
○ → docker run -d -it --name swishtest --entrypoint /bin/bash swishtest
adedea7383d98448990d54fdafb0d9f4884733e1d97375aaf7f93323a0f5f5ea

○ → docker container list
CONTAINER ID   IMAGE       COMMAND       CREATED          STATUS          PORTS     NAMES
adedea7383d9   swishtest   "/bin/bash"   31 seconds ago   Up 31 seconds             swishtest

```
### Connect to the container
```text
○ → docker exec -it swishtest /bin/bash
root@adedea7383d9:/swish#
```
### Verify that both Python3 and Python2 are installed
```text
root@adedea7383d9:/swish# which python3
/usr/bin/python3

root@adedea7383d9:/swish# python3 --version
Python 3.12.3

root@adedea7383d9:/swish# which python2
/usr/local/bin/python2

root@adedea7383d9:/swish# python2 --version
Python 2.7.18
```
### How can we improve build times?
```text
* You could skip the tests by removing the '--enable-optimizations' flag from the configure command like so:
** RUN cd Python-2.7.18 && ./configure && make && make install
```
### Docker URL
```text
https://hub.docker.com/repository/docker/rossethridgexswish/swishtest/general
```
### Resolving CVE's
#### CVE-2018-20225
```text
From our Docker repo we can see that there are a few CVE's from tag 1.0 of the swishtest container.
Tag 2.0 only has a single CVE that is a disputed exploit based on conditions of how it can be exploited.

CVE-2018-20225:
" The only plausible attack is a name collision on the public PyPI index with some company-internal package,  
and that being installed instead of the company-internal version, and that public package on PyPI being malicious.  
That is an astoundingly small window of opportunity, and would very likely be a targeted attack. "
```
### Monitoring
```text
Typically we would use Prometheus to monitor our kube deployments.
There are other great tools out there that cost money, such as DataDog.
Choice depends on budget:
https://prometheus-operator.dev/docs/getting-started/quick-start/
```

## Supporting multiple environments
```text
Best practice for supporting multiple environments is to have different clusters, DEV, STAGE, PROD, etc and a different kubeconfig for each environment  
Rather than re-invent the wheel, I would defer to best practice:

https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/#set-the-kubeconfig-environment-variable

This would refer to different Jenkins jobs that would have a different kubeconfig for each environment:
Like a Kube-Dev job that launched pods on that specific cluster, Kube-Stage and Kube-prod.
Each one targeting a different cluster with different parameters and images.

If using Terraform, I would have a different set of TFVARS for each environment which would simplify it and also allow for modification on the fly based on Terraform variable precedence,
```
## Monitoring and validating
```text
For validating actual state vs expected state I usually rely on tool like OPA (Open Policy Agent)
https://kubernetes.io/blog/2019/08/06/opa-gatekeeper-policy-and-governance-for-kubernetes/

This takes output from actual state and compares it against a set of defined policy and gives you a pass or fail result.

Other helpful tools are Kube-Score. This validates the yaml against deployments but you umay not have YAML if using Terraform:
https://learnk8s.io/validating-kubernetes-yaml#kube-score

OPA also validates the TF code based on state from a terraform plan, so you could validate the TF expected state
https://www.openpolicyagent.org/docs/latest/terraform/

Kube scale sets would allow us to downscale and upscale as needed.
https://kubernetes.io/docs/reference/kubectl/generated/kubectl_scale/
```
## Bringing Data to the Code
```text
For large scale distributed data store I have used Voldemort. This KV store / distributed data base was developed by LinkedIn.
https://en.wikipedia.org/wiki/Voldemort_(distributed_data_store)

It runs in clusters and is horizontally scalable:
https://www.project-voldemort.com/voldemort/

You can add nodes and repartition as needed. 

In my experience the downside was the time it takes to allow for the partition redistributing when adding or subtracting nodes.
It was seamless to the end user but made me a little nervous when I was on call. I would watch and wait for hours sometimes.
Storage would become sparse when removing nodes, but in the cloud its a simple API call to expand volumes.

Again, not re-inventing the wheel for architecture, just using best practice:
https://www.project-voldemort.com/voldemort/design.html
```
