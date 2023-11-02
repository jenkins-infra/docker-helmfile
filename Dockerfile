ARG JENKINS_AGENT_VERSION=3107.v665000b_51092-15-alpine-jdk17
FROM jenkins/inbound-agent:${JENKINS_AGENT_VERSION}
USER root
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

ENV HELM_HOME="/home/helm/.helm"

## Always use the latest Alpine packages
# hadolint ignore=DL3018
RUN apk add --no-cache \
  ca-certificates \
  curl \
  bash \
  git \
  gnupg \
  groff \
  jq \
  less \
  py-pip \
  tar \
  unzip \
  wget \
  yamllint \
  yq

ARG HELM_VERSION=3.13.1
RUN wget "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" --quiet --output-document=/tmp/helm.tgz \
  && tar zxf /tmp/helm.tgz --strip-components 1 -C /usr/local/bin/ \
  && rm -f /tmp/helm.tgz \
  && helm version | grep -q "${HELM_VERSION}"

ARG KUBECTL_VERSION=1.26.10
RUN wget "https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" --quiet --output-document=/usr/local/bin/kubectl \
  && chmod +x /usr/local/bin/kubectl \
  && kubectl version --client --output=yaml 2>&1 | grep -q "${KUBECTL_VERSION}"

# Install sops
ARG SOPS_VERSION=3.8.1
RUN wget "https://github.com/mozilla/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.amd64" --quiet --output-document=/usr/local/bin/sops \
  && chmod +x /usr/local/bin/sops \
  && sops --version | grep -q "${SOPS_VERSION}"

# Install helmfile
ARG HELMFILE_VERSION=0.158.0
RUN wget "https://github.com/helmfile/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_${HELMFILE_VERSION}_linux_amd64.tar.gz" --quiet --output-document=/tmp/helmfile.tgz \
  && tar --extract --gzip --verbose --file=/tmp/helmfile.tgz --directory=/usr/local/bin helmfile \
  && rm -f /tmp/helmfile.tgz \
  && helmfile --version | grep -q "${HELMFILE_VERSION}"

## Install AWS CLI tools
# Please note that only aws cli v1 is supported on alpine - https://github.com/aws/aws-cli/issues/4685
ARG AWS_CLI_VERSION=1.29.75
RUN python3 -m pip install --no-cache-dir awscli=="${AWS_CLI_VERSION}" \
  && aws --version | grep -q "${AWS_CLI_VERSION}"

# Install updatecli
ARG UPDATECLI_VERSION=v0.64.0
RUN wget "https://github.com/updatecli/updatecli/releases/download/${UPDATECLI_VERSION}/updatecli_Linux_x86_64.tar.gz" --quiet --output-document=/usr/local/bin/updatecli.tar.gz \
  && tar zxf /usr/local/bin/updatecli.tar.gz -C /usr/local/bin/ \
  && chmod a+x /usr/local/bin/updatecli \
  && updatecli version \
  && rm -f /usr/local/bin/updatecli.tar.gz

# Install doctl
ARG DOCTL_VERSION=1.96.1
RUN wget "https://github.com/digitalocean/doctl/releases/download/v${DOCTL_VERSION}/doctl-${DOCTL_VERSION}-linux-amd64.tar.gz" --quiet --output-document=/tmp/doctl.tar.gz \
  && tar zxf /tmp/doctl.tar.gz -C /usr/local/bin/ \
  && rm -f /tmp/doctl.tar.gz \
  && chmod +x /usr/local/bin/doctl \
  && doctl version | grep -q "${DOCTL_VERSION}"

## Install Azure Cli
ARG AZ_CLI_VERSION=2.53.1
# hadolint ignore=DL3013,DL3018
RUN apk add --no-cache --virtual .az-build-deps gcc musl-dev python3-dev libffi-dev openssl-dev cargo make \
  && apk add --no-cache py3-pip py3-pynacl py3-cryptography \
  && python3 -m pip install --no-cache-dir azure-cli=="${AZ_CLI_VERSION}" \
  && apk del .az-build-deps

USER jenkins

ARG HELM_DIFF_VERSION=v3.8.1
ARG HELM_SECRETS_VERSION=v4.5.1
ARG HELM_GIT_VERSION=v0.15.1
RUN \
  helm plugin install https://github.com/databus23/helm-diff --version ${HELM_DIFF_VERSION} && \
  helm plugin install https://github.com/jkroepke/helm-secrets --version ${HELM_SECRETS_VERSION} && \
  helm plugin install https://github.com/aslafy-z/helm-git.git --version ${HELM_GIT_VERSION}


## As per https://docs.docker.com/engine/reference/builder/#scope, ARG need to be repeated for each scope
ARG JENKINS_AGENT_VERSION=3107.v665000b_51092-15-alpine-jdk17

LABEL io.jenkins-infra.tools="aws-cli,azure-cli,doctl,helm,helmfile,jenkins-agent,jq,kubectl,sops,updatecli,yamllint,yq"
LABEL io.jenkins-infra.tools.helm.version="${HELM_VERSION}"
LABEL io.jenkins-infra.tools.helm.plugins="helm-diff,helm-git,helm-secrets"
LABEL io.jenkins-infra.tools.helm.plugins.helm-diff.version="${HELM_DIFF_VERSION}"
LABEL io.jenkins-infra.tools.helm.plugins.helm-secrets.version="${HELM_SECRETS_VERSION}"
LABEL io.jenkins-infra.tools.helm.plugins.helm-git.version="${HELM_GIT_VERSION}"
LABEL io.jenkins-infra.tools.kubectl.version="${KUBECTL_VERSION}"
LABEL io.jenkins-infra.tools.sops.version="${SOPS_VERSION}"
LABEL io.jenkins-infra.tools.helmfile.version="${HELMFILE_VERSION}"
LABEL io.jenkins-infra.tools.aws-cli.version="${AWS_CLI_VERSION}"
LABEL io.jenkins-infra.tools.updatecli.version="${UPDATECLI_VERSION}"
LABEL io.jenkins-infra.tools.jenkins-agent.version="${JENKINS_AGENT_VERSION}"
LABEL io.jenkins-infra.tools.doctl.version="${DOCTL_VERSION}"
LABEL io.jenkins-infra.tools.azure-cli.version="${AZ_CLI_VERSION}"

ENTRYPOINT ["/usr/local/bin/jenkins-agent"]
