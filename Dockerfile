FROM registry.centos.org/centos/centos:8 as builder

RUN dnf install -y unzip golang-bin git

# eksctl cli
RUN curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz" | tar xz -C /tmp

# https://github.com/awslabs/amazon-ecr-credential-helper
RUN go get -u github.com/awslabs/amazon-ecr-credential-helper/ecr-login/cli/docker-credential-ecr-login


FROM registry.centos.org/centos/centos:8

COPY --from=builder /tmp/eksctl /bin/
COPY --from=builder /root/go/bin/docker-credential-ecr-login /bin

COPY .docker /root/.docker
COPY demo-yamls /root/demo-yamls
COPY kubernetes.repo google-cloud-sdk.repo /etc/yum.repos.d/

RUN : \
    && dnf install -y kubectl groff-base bash-completion google-cloud-sdk \
    && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && dnf install -y zip \
    && unzip awscliv2.zip \
    && dnf history undo last -y \
    && ./aws/install \
    && rm -rf ./aws \
    && curl  https://download.docker.com/linux/centos/docker-ce.repo > /etc/yum.repos.d/docker-ce.repo \
    && dnf install -y docker-ce docker-ce-cli containerd.io \
    && dnf clean all \
    && rm -rf /var/cache/dnf

RUN echo $'\n\
complete -C '/usr/local/bin/aws_completer' aws \n\
' >> /etc/bashrc \
  && kubectl completion bash >/etc/bash_completion.d/kubectl \
  && eksctl completion bash >/etc/bash_completion.d/eksctl
