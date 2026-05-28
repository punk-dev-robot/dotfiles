# METADATA
# scope: package
# custom:
#   entrypoint: true
# title: Global System Evaluation Aggregator
# description: |
#   This is the global namespace system evaluation policy.
#   It aggregates decision verbs from all global policies.
package cupcake.global.system

import rego.v1

# Aggregate all decision verbs from global policies
halts := collect_verbs("halt")
denials := collect_verbs("deny")
blocks := collect_verbs("block")
asks := collect_verbs("ask")
modifications := collect_verbs("modify")
add_context := collect_verbs("add_context")

# Main evaluation entrypoint
evaluate := {
    "halts": halts,
    "denials": denials,
    "blocks": blocks,
    "asks": asks,
    "modifications": modifications,
    "add_context": add_context
}

# Default implementation returns empty array
default collect_verbs(_) := []

# Collect all instances of a specific verb from all policies
collect_verbs(verb_name) := result if {
    verb_sets := [value |
        walk(data.cupcake.global.policies, [path, value])
        path[count(path) - 1] == verb_name
    ]
    all_decisions := [decision |
        some verb_set in verb_sets
        some decision in verb_set
    ]
    result := all_decisions
}
