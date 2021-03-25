---
title: "[helmfile] Update version"
source:
  kind: githubRelease
  name: Get the latest helmfile version
  transformers:
    - trimPrefix: "v"
  spec:
    owner: "roboll"
    repository: "helmfile"
    token: "{{ requiredEnv .github.token }}"
    username: "{{ .github.username }}"
    version: "latest"
conditions:
  dockerfileArgHelmfileVersion:
    name: "Does the Dockerfile have an ARG instruction which key is HELMFILE_VERSION?"
    kind: dockerfile
    spec:
      file: Dockerfile
      instruction:
        keyword: "ARG"
        matcher: "HELMFILE_VERSION"
targets:
  updateCstHelmfileVersion:
    name: "Update the value of HELMFILE_VERSION in the test harness"
    kind: yaml
    spec:
      file: "cst.yml"
      key: "metadataTest.labels[2].value"
    scm:
      github:
        user: "{{ .github.user }}"
        email: "{{ .github.email }}"
        owner: "{{ .github.owner }}"
        repository: "{{ .github.repository }}"
        token: "{{ requiredEnv .github.token }}"
        username: "{{ .github.username }}"
        branch: "{{ .github.branch }}"
  updateDockerfileArgHelmfileVersion:
    name: "Update the value of ARG HELMFILE_VERSION in the Dockerfile"
    kind: dockerfile
    spec:
      file: Dockerfile
      instruction:
        keyword: "ARG"
        matcher: "HELMFILE_VERSION"
    scm:
      github:
        user: "{{ .github.user }}"
        email: "{{ .github.email }}"
        owner: "{{ .github.owner }}"
        repository: "{{ .github.repository }}"
        token: "{{ requiredEnv .github.token }}"
        username: "{{ .github.username }}"
        branch: "{{ .github.branch }}"
