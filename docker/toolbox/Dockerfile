FROM alpine:3.10

ENV BINDIR /usr/local/bin
ENV TF_PLUGIN_CACHE_DIR=$HOME/.terraform.d/plugin-cache
ARG TERRAFORM_VERSION=0.12.17
ARG HELM_VERSION=v2.16.1
ARG TERRAGRUNT_VERSION=v0.21.6
ARG KUBECTL_VERSION=v1.14.8
ARG AWS_IAM_AUTHENTICATOR_VERSION=0.4.0

COPY --from=terraform-bundler-build /go/terraform-bundle/* $TF_PLUGIN_CACHE_DIR/

RUN apk add -U unzip \
               tar \
               curl \
               wget \
               ca-certificates \
               py3-pip \
               sed \
               findutils \
               git \
               bash \
    && rm -rf /var/cache/apk/*

RUN pip3 install -U pip \
    && pip3 install -U awscli \
    && aws --version

RUN curl -sSL \
          -o terraform.zip \
          "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
    && unzip terraform.zip -d $BINDIR \
    && chmod +x $BINDIR/terraform \
    && rm -f terraform.zip \
    && terraform version

RUN curl -L https://github.com/gruntwork-io/terragrunt/releases/download/${TERRAGRUNT_VERSION}/terragrunt_linux_amd64 -o $BINDIR/terragrunt \
    && chmod +x $BINDIR/terragrunt \
    && terragrunt --version

RUN wget -qO- "https://storage.googleapis.com/kubernetes-helm/helm-${HELM_VERSION}-linux-amd64.tar.gz" | \
    tar xvz --strip-components=1 -C $BINDIR \
    && chmod +x $BINDIR/helm \
    && helm version --client

RUN curl -L https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl -o $BINDIR/kubectl \
    && chmod +x $BINDIR/kubectl \
    && kubectl version --client

RUN curl -L https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v${AWS_IAM_AUTHENTICATOR_VERSION}/aws-iam-authenticator_${AWS_IAM_AUTHENTICATOR_VERSION}_linux_amd64 -o $BINDIR/aws-iam-authenticator \
    && chmod +x $BINDIR/aws-iam-authenticator \
    && aws-iam-authenticator version

COPY . /infra

WORKDIR /infra/terraform
