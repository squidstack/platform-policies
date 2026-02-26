package main

# =============================================================================
# Terraform Resource Tagging Policy
# =============================================================================
#
# Purpose: Enforce consistent tagging across all cloud resources for cost
#          allocation, ownership tracking, and compliance.
#
# Mode: WARNING (non-blocking by default)
#       Set data.config.enforce = true to make violations blocking
#
# Owner: Platform Engineering & Security Team
# =============================================================================

# -----------------------------------------------------------------------------
# Required Tags
# -----------------------------------------------------------------------------
# - Environment: Deployment environment (dev, staging, prod)
# - Owner: Team or individual responsible for the resource
# - CostCenter: Billing allocation code for chargeback
# -----------------------------------------------------------------------------

required_tags := ["Environment", "Owner", "CostCenter"]

# -----------------------------------------------------------------------------
# Warning Mode (default): Non-blocking governance
# -----------------------------------------------------------------------------

# Warn about resources missing required tags
warn[msg] {
  resource := input.resource_changes[_]
  resource.change.actions[_] == "create"

  # Check if resource supports tags
  has_tags_field(resource)

  # Check for missing required tags
  missing_tag := required_tags[_]
  not resource.change.after.tags[missing_tag]

  msg := sprintf(
    "Resource '%s' (type: %s) is missing recommended tag: %s",
    [resource.address, resource.type, missing_tag]
  )
}

# Warn about invalid Environment tag values
warn[msg] {
  resource := input.resource_changes[_]
  resource.change.actions[_] == "create"

  has_tags_field(resource)
  env_tag := resource.change.after.tags.Environment

  # Environment tag exists but has invalid value
  valid_environments := ["dev", "staging", "prod"]
  not env_tag in valid_environments

  msg := sprintf(
    "Resource '%s' has non-standard Environment tag: '%s'. Recommended: %s",
    [resource.address, env_tag, concat(", ", valid_environments)]
  )
}

# -----------------------------------------------------------------------------
# Enforcement Mode (optional): Blocking governance
# -----------------------------------------------------------------------------
# Uncomment the deny rules below to block deployments for policy violations
# Or use: data.config.enforce = true in your conftest configuration
# -----------------------------------------------------------------------------

# Example: Block resources without required tags (commented out)
# deny[msg] {
#   resource := input.resource_changes[_]
#   resource.change.actions[_] == "create"
#
#   has_tags_field(resource)
#
#   missing_tag := required_tags[_]
#   not resource.change.after.tags[missing_tag]
#
#   msg := sprintf(
#     "BLOCKED: Resource '%s' (type: %s) must have tag: %s",
#     [resource.address, resource.type, missing_tag]
#   )
# }

# Example: Conditional enforcement based on configuration
# deny[msg] {
#   data.config.enforce == true
#   resource := input.resource_changes[_]
#   resource.change.actions[_] == "create"
#
#   has_tags_field(resource)
#
#   missing_tag := required_tags[_]
#   not resource.change.after.tags[missing_tag]
#
#   msg := sprintf(
#     "BLOCKED: Resource '%s' (type: %s) must have tag: %s",
#     [resource.address, resource.type, missing_tag]
#   )
# }

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------

# Check if a resource supports tags
has_tags_field(resource) {
  resource.change.after.tags
}

# Check if a resource is being created or updated
is_create_or_update(resource) {
  actions := {"create", "update"}
  resource.change.actions[_] == actions[_]
}
