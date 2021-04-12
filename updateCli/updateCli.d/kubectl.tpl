---
title: "[kubectl] Update version"
sources:
  default:
    kind: githubRelease
    name: Get the latest kubectl version
    transformers:
      - trimPrefix: "kubernetes-"
    spec:
      owner: "kubernetes"
      repository: "kubectl"
      token: "{{ requiredEnv .github.token }}"
      username: "{{ .github.username }}"
      versionFilter:
        kind: regex
        pattern: "^kubernetes-1.18.(\\d*)$"
conditions:
  dockerfileArgKubectlVersion:
    name: "Does the Dockerfile have an ARG instruction which key is KUBECTL_VERSION?"
    kind: dockerfile
    spec:
      file: Dockerfile
      instruction:
        keyword: "ARG"
        matcher: "KUBECTL_VERSION"
  testCstKubectlVersion:
    name: "Update the value of KUBECTL_VERSION in the test harness"
    kind: yaml
    spec:
      file: "cst.yml"
      key: "metadataTest.labels[4].key"
      value: "io.jenkins-infra.tools.kubectl.version"
    scm:
      github:
        user: "{{ .github.user }}"
        email: "{{ .github.email }}"
        owner: "{{ .github.owner }}"
        repository: "{{ .github.repository }}"
        token: "{{ requiredEnv .github.token }}"
        username: "{{ .github.username }}"
        branch: "{{ .github.branch }}"
targets:
  updateCstKubectlVersion:
    name: "Update the value of KUBECTL_VERSION in the test harness"
    kind: yaml
    spec:
      file: "cst.yml"
      key: "metadataTest.labels[4].value"
    scm:
      github:
        user: "{{ .github.user }}"
        email: "{{ .github.email }}"
        owner: "{{ .github.owner }}"
        repository: "{{ .github.repository }}"
        token: "{{ requiredEnv .github.token }}"
        username: "{{ .github.username }}"
        branch: "{{ .github.branch }}"
  updateDockerfileArgKubectlVersion:
    name: "Update the value of ARG KUBECTL_VERSION in the Dockerfile"
    kind: dockerfile
    spec:
      file: Dockerfile
      instruction:
        keyword: "ARG"
        matcher: "KUBECTL_VERSION"
    scm:
      github:
        user: "{{ .github.user }}"
        email: "{{ .github.email }}"
        owner: "{{ .github.owner }}"
        repository: "{{ .github.repository }}"
        token: "{{ requiredEnv .github.token }}"
        username: "{{ .github.username }}"
        branch: "{{ .github.branch }}"
