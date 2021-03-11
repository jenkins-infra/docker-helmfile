FROM alpine:3.13

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

ENV HELM_HOME="/home/helm/.helm"

# hadolint ignore=DL3018
RUN \
  apk add --no-cache gnupg wget ca-certificates git bash curl

# Install kubectl
ARG HELM_VERSION=v3.2.1
ARG HELM_LOCATION="https://get.helm.sh"
ARG HELM_FILENAME="helm-${HELM_VERSION}-linux-amd64.tar.gz"
ARG HELM_SHA256="018f9908cb950701a5d59e757653a790c66d8eda288625dbb185354ca6f41f6b"
RUN wget ${HELM_LOCATION}/${HELM_FILENAME} && \
    sha256sum ${HELM_FILENAME} | grep -q "${HELM_SHA256}" && \
    tar zxf ${HELM_FILENAME} && mv /linux-amd64/helm /usr/local/bin/ && \
    rm ${HELM_FILENAME} && rm -r /linux-amd64

# Install helm
ARG KUBECTL_VERSION=v1.15.12
ARG KUBECTL_SHA256="a32b762279c33cb8d8f4198f3facdae402248c3164e9b9b664c3afbd5a27472e"
RUN wget "https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" -O kubectl && \
    sha256sum kubectl | grep ${KUBECTL_SHA256} && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/kubectl

# Install sops
ARG SOPS_VERSION="v3.5.0"
RUN \
  wget https://github.com/mozilla/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux -O /usr/local/bin/sops && \
  chmod +x /usr/local/bin/sops

# Install helmfile
ARG HELMFILE_VERSION="0.116.0"
RUN \
  wget https://github.com/roboll/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_linux_amd64 -O /usr/local/bin/helmfile && \
  chmod +x /usr/local/bin/helmfile

# Install aws CLi tools
ARG AWS_CLI_VERSION=1.18
RUN apk add --no-cache aws-cli=~"${AWS_CLI_VERSION}"
RUN wget https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/aws-iam-authenticator -O /usr/local/bin/aws-iam-authenticator \
  && chmod a+x /usr/local/bin/aws-iam-authenticator \
  && aws-iam-authenticator version

RUN adduser -D -u 1000 helm

USER helm

WORKDIR /home/helm

RUN \
  helm plugin install https://github.com/databus23/helm-diff && \
  helm plugin install https://github.com/futuresimple/helm-secrets && \
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
