# METADATA
# scope: package
# custom:
#   routing:
#     required_events: ["UserPromptSubmit"]
# title: Example Global Policy
# description: |
#   This is an example global policy that applies to all Cupcake projects
#   on this machine. Global policies take absolute precedence over project policies.
#
#   To activate: Uncomment the rules below and customize for your needs.
package cupcake.global.policies.example

import rego.v1

# Example: Add context to all prompts
# add_context contains "Global policy monitoring active"

# Example: Deny dangerous operations globally
# deny contains decision if {
#     input.hook_event_name == "PreToolUse"
#     input.tool_name == "Bash"
#     contains(input.tool_input.command, "rm -rf /")
#     decision := {
#         "rule_id": "GLOBAL-SAFETY-001",
#         "reason": "Dangerous system command blocked by global policy",
#         "severity": "CRITICAL"
#     }
# }

# Example: Halt on specific conditions
# halt contains decision if {
#     input.hook_event_name == "UserPromptSubmit"
#     contains(lower(input.prompt), "malicious")
#     decision := {
#         "rule_id": "GLOBAL-SECURITY-001",
#         "reason": "Potentially malicious prompt detected",
#         "severity": "CRITICAL"
#     }
# }
