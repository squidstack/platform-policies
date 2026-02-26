package main

# =============================================================================
# Terraform Resource Tagging Policy
# =============================================================================
#
# Purpose: Enforce consistent tagging across all cloud resources for cost
#          allocation, ownership tracking, and compliance.
#
# Status: DEMO MODE - This policy PASSES by default
#         Uncomment the deny rules below to enforce tagging requirements
#
# Owner: Platform Engineering & Security Team
# =============================================================================

# -----------------------------------------------------------------------------
# Required Tags (when enforcement is enabled)
# -----------------------------------------------------------------------------
# - Environment: Deployment environment (dev, staging, prod)
# - Owner: Team or individual responsible for the resource
# - CostCenter: Billing allocation code for chargeback
# -----------------------------------------------------------------------------

# Example: Deny resources without required tags
# Uncomment the block below to enforce tagging requirements

# required_tags := ["Environment", "Owner", "CostCenter"]
#
# deny[msg] {
#   resource := input.resource_changes[_]
#   resource.change.actions[_] == "create"
#
#   # Check if resource supports tags
#   has_tags_field(resource)
#
#   # Check for missing required tags
#   missing_tag := required_tags[_]
#   not resource.change.after.tags[missing_tag]
#
#   msg := sprintf(
#     "Resource '%s' (type: %s) is missing required tag: %s",
#     [resource.address, resource.type, missing_tag]
#   )
# }

# Example: Validate Environment tag values
# Uncomment the block below to enforce valid environment values

# valid_environments := ["dev", "staging", "prod"]
#
# deny[msg] {
#   resource := input.resource_changes[_]
#   resource.change.actions[_] == "create"
#
#   has_tags_field(resource)
#   env_tag := resource.change.after.tags.Environment
#
#   # Environment tag exists but has invalid value
#   not env_tag in valid_environments
#
#   msg := sprintf(
#     "Resource '%s' has invalid Environment tag: '%s'. Must be one of: %s",
#     [resource.address, env_tag, concat(", ", valid_environments)]
#   )
# }

# Example: Warn about missing optional tags
# Uncomment the block below to add warnings (non-blocking)

# optional_tags := ["Project", "ManagedBy"]
#
# warn[msg] {
#   resource := input.resource_changes[_]
#   resource.change.actions[_] == "create"
#
#   has_tags_field(resource)
#
#   missing_tag := optional_tags[_]
#   not resource.change.after.tags[missing_tag]
#
#   msg := sprintf(
#     "Resource '%s' is missing optional tag: %s (recommended)",
#     [resource.address, missing_tag]
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

# -----------------------------------------------------------------------------
# Demo Policy - Always Passes
# -----------------------------------------------------------------------------
# This rule ensures the policy passes by default for demo purposes
# Remove this when enabling real tag enforcement above

# This empty package with no deny rules will pass all tests
# Conftest returns success when no violations are found
