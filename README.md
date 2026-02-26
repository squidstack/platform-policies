# Platform Policies

**Policy-as-Code for CloudBees Unify Governance**

## Overview

This repository contains governance policies enforced across infrastructure and application deployments. Policies are written in [Rego](https://www.openpolicyagent.org/docs/latest/policy-language/) (Open Policy Agent) and evaluated using [Conftest](https://www.conftest.dev/).

## Governance Separation Model

This repository demonstrates a **decoupled governance model** where:

- **Application/IaC teams** own their code repositories (Terraform, Kubernetes manifests, etc.)
- **Platform/Security team** owns this policy repository
- **CloudBees Unify workflows** enforce policies at deployment time by checking out both repos

This separation enables:

✅ Centralized policy management
✅ Independent policy versioning
✅ Clear ownership boundaries
✅ Reusable policies across multiple projects
✅ Security team control without blocking development velocity

## Using Policies in CloudBees Unify

### Step 1: Checkout Your Application Code

```yaml
- name: Checkout application repository
  uses: cloudbees-io/checkout@v2
```

### Step 2: Checkout Platform Policies

```yaml
- name: Checkout platform policies
  uses: cloudbees-io/checkout@v2
  with:
    repository: https://github.com/squidstack/platform-policies
    ref: main
    path: platform-policies
```

### Step 3: Run Conftest Policy Evaluation

```yaml
- name: Policy validation
  uses: docker://alpine:3.20
  shell: sh
  run: |
    apk add --no-cache curl tar
    curl -L https://github.com/open-policy-agent/conftest/releases/download/v0.49.1/conftest_0.49.1_Linux_x86_64.tar.gz | tar xz
    chmod +x conftest

    ./conftest test plan.json -p platform-policies/policies/terraform
```

## Repository Structure

```
platform-policies/
├── README.md                          # This file
├── policies/
│   └── terraform/
│       ├── README.md                  # Terraform policy documentation
│       └── tags.rego                  # Tag enforcement policy
└── examples/
    └── terraform/
        └── plan.json                  # Sample Terraform plan for testing
```

## Policy Categories

### Terraform Policies (`policies/terraform/`)

Policies for Terraform infrastructure-as-code validation:

- **tags.rego** - Resource tagging requirements (cost center, owner, environment)
- Future: naming conventions, security groups, encryption requirements

### Future Policy Categories

- **Kubernetes** (`policies/kubernetes/`) - Pod security, resource limits, namespace policies
- **Docker** (`policies/docker/`) - Base image requirements, security scanning
- **Cloud Provider** (`policies/cloud/`) - Service-specific policies (S3 encryption, IAM roles)

## Versioning Model

Policies follow semantic versioning and are tagged for stability:

- **main branch** - Latest stable policies (safe for production workflows)
- **develop branch** - Policy development and testing
- **Tags/Releases** - Immutable policy versions (e.g., `v1.0.0`, `v1.1.0`)

### Pinning to Specific Versions

```yaml
- name: Checkout platform policies
  uses: cloudbees-io/checkout@v2
  with:
    repository: https://github.com/squidstack/platform-policies
    ref: v1.0.0  # Pin to specific version
    path: platform-policies
```

## Local Testing

### Install Conftest

```bash
# macOS
brew install conftest

# Linux
curl -L https://github.com/open-policy-agent/conftest/releases/download/v0.49.1/conftest_0.49.1_Linux_x86_64.tar.gz | tar xz
sudo mv conftest /usr/local/bin/
```

### Test Policies Locally

```bash
# Test with example plan
conftest test examples/terraform/plan.json -p policies/terraform/

# Test your own plan
terraform plan -out=tfplan
terraform show -json tfplan > plan.json
conftest test plan.json -p policies/terraform/
```

## Ownership

**Owner:** Platform Engineering & Security Team

This repository is managed by the platform and security teams to ensure consistent governance across all infrastructure and application deployments. Application teams consume these policies but do not modify them directly.

For policy change requests or questions, contact:

- Platform Engineering Team: platform-team@example.com
- Security Team: security@example.com

## Contributing

Policy changes require approval from both platform and security teams:

1. Fork this repository
2. Create a feature branch (`feature/new-policy`)
3. Add/modify policies with clear documentation
4. Test policies locally with example data
5. Submit PR with rationale and impact analysis
6. Await review from platform & security teams

## References

- [Open Policy Agent Documentation](https://www.openpolicyagent.org/docs/latest/)
- [Conftest Documentation](https://www.conftest.dev/)
- [Rego Language Guide](https://www.openpolicyagent.org/docs/latest/policy-language/)
- [CloudBees Unify Documentation](https://docs.cloudbees.com/docs/cloudbees-platform/)
