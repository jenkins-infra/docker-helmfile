---
title: "[sops] Update version"
source:
  kind: githubRelease
  name: Get the latest SOPS version
  transformers:
    - trimPrefix: "v"
  spec:
    owner: "mozilla"
    repository: "sops"
    token: "{{ requiredEnv .github.token }}"
    username: "{{ .github.username }}"
    version: "latest"
conditions:
  dockerfileArgSopsVersion:
    name: "Does the Dockerfile have an ARG instruction which key is SOPS_VERSION?"
    kind: dockerfile
    spec:
      file: Dockerfile
      instruction:
        keyword: "ARG"
        matcher: "SOPS_VERSION"
targets:
  updateCstSopsVersion:
    name: "Update the value of SOPS_VERSION in the test harness"
    kind: yaml
    spec:
      file: "cst.yml"
      key: "metadataTest.labels[5].value"
    scm:
      github:
        user: "{{ .github.user }}"
        email: "{{ .github.email }}"
        owner: "{{ .github.owner }}"
        repository: "{{ .github.repository }}"
        token: "{{ requiredEnv .github.token }}"
        username: "{{ .github.username }}"
        branch: "{{ .github.branch }}"
  updateDockerfileArgSopsVersion:
    name: "Update the value of ARG SOPS_VERSION in the Dockerfile"
    kind: dockerfile
    spec:
      file: Dockerfile
      instruction:
        keyword: "ARG"
        matcher: "SOPS_VERSION"
    scm:
      github:
        user: "{{ .github.user }}"
        email: "{{ .github.email }}"
        owner: "{{ .github.owner }}"
        repository: "{{ .github.repository }}"
        token: "{{ requiredEnv .github.token }}"
        username: "{{ .github.username }}"
        branch: "{{ .github.branch }}"
