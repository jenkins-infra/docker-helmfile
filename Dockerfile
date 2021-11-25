FROM alpine:3.13

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

ENV HELM_HOME="/home/helm/.helm"

# hadolint ignore=DL3018
RUN apk add --no-cache \
  ca-certificates \
  curl \
  bash \
  git \
  gnupg \
  tar \
  unzip \
  wget

ARG HELM_VERSION=3.6.3
RUN wget "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" --quiet --output-document=/tmp/helm.tgz \
    && tar zxf /tmp/helm.tgz --strip-components 1 -C /usr/local/bin/ \
    && rm /tmp/* \
    && helm version | grep -q "${HELM_VERSION}"

ARG KUBECTL_VERSION=1.20.9
RUN wget "https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" --quiet --output-document=/usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl \
    && kubectl version --client | grep -q "${KUBECTL_VERSION}"

# Install sops
ARG SOPS_VERSION=3.7.1
RUN wget "https://github.com/mozilla/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux" --quiet --output-document=/usr/local/bin/sops \
  && chmod +x /usr/local/bin/sops \
  && sops --version | grep -q "${SOPS_VERSION}"

# Install helmfile
ARG HELMFILE_VERSION=0.142.0
RUN wget "https://github.com/roboll/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_linux_amd64" --quiet --output-document=/usr/local/bin/helmfile \
  && chmod +x /usr/local/bin/helmfile \
  && helmfile --version | grep -q "${HELMFILE_VERSION}"

## Install aws CLiI tools
# Please note that only aws cli v1 is supported on alpine - https://github.com/aws/aws-cli/issues/4685
ARG AWS_CLI_VERSION=1.18
# hadolint ignore=DL3018
RUN apk add --no-cache aws-cli=~"${AWS_CLI_VERSION}" less groff \
  && aws --version | grep -q "${AWS_CLI_VERSION}"
ARG AWS_IAM_AUTH_VERSION="1.19.6"
RUN wget "https://amazon-eks.s3.us-west-2.amazonaws.com/${AWS_IAM_AUTH_VERSION}/2021-01-05/bin/linux/amd64/aws-iam-authenticator" --quiet --output-document=/usr/local/bin/aws-iam-authenticator \
  && chmod a+x /usr/local/bin/aws-iam-authenticator \
  && aws-iam-authenticator version

RUN adduser -D -u 1000 helm

USER helm

WORKDIR /home/helm

RUN \
  helm plugin install https://github.com/databus23/helm-diff && \
  helm plugin install https://github.com/jkroepke/helm-secrets --version v3.9.1 && \
  helm plugin install https://github.com/aslafy-z/helm-git.git

LABEL io.jenkins-infra.tools="helm,kubectl,helmfile,sops,aws-cli,aws-iam-authenticator"
LABEL io.jenkins-infra.tools.helm.version="${HELM_VERSION}"
LABEL io.jenkins-infra.tools.helm.plugins="helm-diff,helm-git,helm-secrets"
LABEL io.jenkins-infra.tools.kubectl.version="${KUBECTL_VERSION}"
LABEL io.jenkins-infra.tools.sops.version="${SOPS_VERSION}"
LABEL io.jenkins-infra.tools.helmfile.version="${HELMFILE_VERSION}"
LABEL io.jenkins-infra.tools.aws-cli.version="${AWS_CLI_VERSION}"
LABEL io.jenkins-infra.tools.aws-iam-authenticator.version="latest"

ENTRYPOINT ["/usr/local/bin/helmfile"]
