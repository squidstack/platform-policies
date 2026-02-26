# Terraform Governance Policies

This directory contains Open Policy Agent (OPA) policies for validating Terraform plans before infrastructure changes are applied.

## How It Works

Terraform plan validation happens in three steps:

1. **Generate Terraform Plan**
   ```bash
   terraform plan -out=tfplan
   ```

2. **Convert Plan to JSON**
   ```bash
   terraform show -json tfplan > plan.json
   ```

3. **Evaluate with Conftest**
   ```bash
   conftest test plan.json -p policies/terraform/
   ```

## Plan JSON Structure

The Terraform plan JSON contains:

```json
{
  "format_version": "1.0",
  "terraform_version": "1.5.0",
  "resource_changes": [
    {
      "address": "aws_instance.example",
      "type": "aws_instance",
      "change": {
        "actions": ["create"],
        "before": null,
        "after": {
          "tags": {
            "Name": "example-instance",
            "Environment": "dev"
          }
        }
      }
    }
  ]
}
```

Policies evaluate this JSON structure using Rego rules.

## Policy Files

### tags.rego

**Purpose:** Enforce resource tagging standards for cost allocation and ownership tracking.

**Status:** Demo mode - passes by default, includes commented examples for real enforcement.

**Required Tags (when enabled):**
- `Environment` - Deployment environment (dev/staging/prod)
- `Owner` - Team or individual responsible for the resource
- `CostCenter` - Billing allocation code

## Testing Policies Locally

### Quick Test with Example Data

```bash
conftest test examples/terraform/plan.json -p policies/terraform/
```

### Test with Your Terraform Plan

```bash
# In your Terraform directory
terraform init
terraform plan -out=tfplan
terraform show -json tfplan > plan.json

# Test against policies
conftest test plan.json -p /path/to/platform-policies/policies/terraform/
```

### Expected Output (Success)

```
PASS - examples/terraform/plan.json
```

### Expected Output (Failure)

```
FAIL - plan.json - Resource 'aws_instance.example' is missing required tag: Environment
FAIL - plan.json - Resource 'aws_instance.example' is missing required tag: Owner

2 tests, 0 passed, 0 warnings, 2 failures, 0 exceptions
```

## Policy Development

### Adding a New Policy

1. Create a new `.rego` file in this directory
2. Follow Rego naming conventions:
   - Package should be `main`
   - Use `deny[msg]` for violations
   - Use `warn[msg]` for warnings

3. Example template:

```rego
package main

# Deny resources without encryption
deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "aws_s3_bucket"
  not resource.change.after.encryption

  msg := sprintf("S3 bucket '%s' must have encryption enabled", [resource.address])
}
```

### Testing Policy Changes

Always test policies against example data before deploying:

```bash
# Test passes
conftest test examples/terraform/plan-valid.json -p policies/terraform/

# Test fails as expected
conftest test examples/terraform/plan-invalid.json -p policies/terraform/
```

## CloudBees Unify Integration

These policies are consumed by CloudBees Unify workflows:

```yaml
- name: Checkout platform policies
  uses: cloudbees-io/checkout@v2
  with:
    repository: https://github.com/squidstack/platform-policies
    ref: main
    path: platform-policies

- name: Policy validation
  uses: docker://alpine:3.20
  shell: sh
  run: |
    apk add --no-cache curl tar
    curl -L https://github.com/open-policy-agent/conftest/releases/download/v0.49.1/conftest_0.49.1_Linux_x86_64.tar.gz | tar xz
    chmod +x conftest

    ./conftest test plan.json -p platform-policies/policies/terraform/
```

## References

- [Terraform JSON Plan Format](https://www.terraform.io/internals/json-format)
- [Conftest Terraform Tutorial](https://www.conftest.dev/examples/#terraform)
- [OPA Rego Language](https://www.openpolicyagent.org/docs/latest/policy-language/)
