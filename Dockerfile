FROM jenkins/inbound-agent:4.11.2-2-alpine-jdk11
USER root
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

ARG KUBECTL_VERSION=1.20.14
RUN wget "https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" --quiet --output-document=/usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl \
    && kubectl version --client | grep -q "${KUBECTL_VERSION}"

# Install sops
ARG SOPS_VERSION=3.7.1
RUN wget "https://github.com/mozilla/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux" --quiet --output-document=/usr/local/bin/sops \
  && chmod +x /usr/local/bin/sops \
  && sops --version | grep -q "${SOPS_VERSION}"

# Install helmfile
ARG HELMFILE_VERSION=0.143.0
RUN wget "https://github.com/roboll/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_linux_amd64" --quiet --output-document=/usr/local/bin/helmfile \
  && chmod +x /usr/local/bin/helmfile \
  && helmfile --version | grep -q "${HELMFILE_VERSION}"

## Install aws CLiI tools
# Please note that only aws cli v1 is supported on alpine - https://github.com/aws/aws-cli/issues/4685
ARG AWS_CLI_VERSION=1.19
ARG YAMLLINT_VERSION=1.26
ARG UPDATECLI_VERSION=v0.18.2
# hadolint ignore=DL3018
RUN apk add --no-cache aws-cli=~"${AWS_CLI_VERSION}" yamllint=~"${YAMLLINT_VERSION}" less groff \
  && aws --version | grep -q "${AWS_CLI_VERSION}"
ARG AWS_IAM_AUTH_VERSION="1.19.6"
RUN wget "https://amazon-eks.s3.us-west-2.amazonaws.com/${AWS_IAM_AUTH_VERSION}/2021-01-05/bin/linux/amd64/aws-iam-authenticator" --quiet --output-document=/usr/local/bin/aws-iam-authenticator \
  && chmod a+x /usr/local/bin/aws-iam-authenticator \
  && aws-iam-authenticator version

RUN wget "https://github.com/updatecli/updatecli/releases/download/${UPDATECLI_VERSION}/updatecli_Linux_x86_64.tar.gz" --quiet --output-document=/usr/local/bin/updatecli.tar.gz \
  && tar zxf /usr/local/bin/updatecli.tar.gz -C /usr/local/bin/ \
  && chmod a+x /usr/local/bin/updatecli \
  && updatecli version \
  && rm /usr/local/bin/updatecli.tar.gz

USER jenkins

ARG HELM_DIFF_VERSION=v3.3.2
ARG HELM_SECRETS_VERSION=v3.11.0
ARG HELM_GIT_VERSION=v0.11.1
RUN \
  helm plugin install https://github.com/databus23/helm-diff --version ${HELM_DIFF_VERSION} && \
  helm plugin install https://github.com/jkroepke/helm-secrets --version ${HELM_SECRETS_VERSION} && \
  helm plugin install https://github.com/aslafy-z/helm-git.git --version ${HELM_GIT_VERSION}

LABEL io.jenkins-infra.tools="helm,kubectl,helmfile,sops,aws-cli,aws-iam-authenticator,yamllint,updatecli"
LABEL io.jenkins-infra.tools.helm.version="${HELM_VERSION}"
LABEL io.jenkins-infra.tools.helm.plugins="helm-diff,helm-git,helm-secrets"
LABEL io.jenkins-infra.tools.helm.plugins.helm-diff.version="${HELM_DIFF_VERSION}"
LABEL io.jenkins-infra.tools.helm.plugins.helm-secrets.version="${HELM_SECRETS_VERSION}"
LABEL io.jenkins-infra.tools.helm.plugins.helm-git.version="${HELM_GIT_VERSION}"
LABEL io.jenkins-infra.tools.kubectl.version="${KUBECTL_VERSION}"
LABEL io.jenkins-infra.tools.sops.version="${SOPS_VERSION}"
LABEL io.jenkins-infra.tools.helmfile.version="${HELMFILE_VERSION}"
LABEL io.jenkins-infra.tools.aws-cli.version="${AWS_CLI_VERSION}"
LABEL io.jenkins-infra.tools.yamllint.version="${YAMLLINT_VERSION}"
LABEL io.jenkins-infra.tools.updatecli.version="${UPDATECLI_VERSION}"
LABEL io.jenkins-infra.tools.aws-iam-authenticator.version="latest"

ENTRYPOINT ["/usr/local/bin/jenkins-agent"]
