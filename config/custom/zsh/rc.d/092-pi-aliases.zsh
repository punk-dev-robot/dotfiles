#!/bin/zsh
##
# Pi coding-agent session launchers — multi-agent orchestration roles.
#
# Design: docs/plans/2026-07-27-pi-multi-agent-orchestration-design.md
#
# `pi` itself is left FULL (default model, all tools + skills); skill curation
# is deferred (P1). These launch role-flavored sessions. Anthropic tier ladder
# (cheap -> expensive): haiku-4-5 < sonnet-5 < opus-5 < fable-5 (ceiling).
# The principal/advisor is also borrowable on demand via pi-advisor-flow
# (`/advisor`), independent of these launchers.
#
# `command pi` bypasses any alias, so nothing recurses. Functions forward "$@",
# so you can still append a prompt or flags, e.g. `pim "start epic AGI-5099"`.
##

# Full / unrestricted escape hatch — current default model, all tools + skills.
alias pif='command pi'

# Recon — read-only, cheapest tier. Primary haiku-4-5, Ctrl+P alt gpt-5.6-luna.
# No skills, read-only native tools only.
alias pir='command pi --model anthropic/claude-haiku-4-5 --models anthropic/claude-haiku-4-5,openai-codex/gpt-5.6-luna --no-skills --tools read,grep,find,ls'

# Principal / architect — ceiling model (fable-5). Deep design partner to the
# manager; allocates tiers, adjudicates specialist disagreements. To make it your
# default: alias pi=pip.
pip() {
  command pi --model anthropic/claude-fable-5 \
    --append-system-prompt "You are the principal engineer/architect. Partner with the manager on hard design decisions, allocate model tiers per task (default cheap, escalate only when consequential), resolve cross-cutting architecture, and adjudicate specialist disagreements. Reason deeply and delegate execution rather than implementing yourself." \
    "$@"
}

# Manager / orchestrator — delegation-focused. Primary opus-4-8, Ctrl+P alt gpt-5.6-sol.
pim() {
  command pi --model anthropic/claude-opus-4-8 --models anthropic/claude-opus-4-8,openai-codex/gpt-5.6-sol \
    --append-system-prompt "You are the orchestration manager. Keep your context on the big picture: decompose the epic, track dependencies, remove duplicates, and delegate work to specialist subagents via the task tool. Avoid doing implementation yourself; borrow deep reasoning via /advisor only when a decision is consequential." \
    "$@"
}

# Dev / implementer — opus-4-8 (good taste, esp. FE). Primary opus-4-8, Ctrl+P alt
# gpt-5.6-terra. Full tools (skill curation: P1).
pid() {
  command pi --model anthropic/claude-opus-4-8 --models anthropic/claude-opus-4-8,openai-codex/gpt-5.6-terra \
    --append-system-prompt "You are a hands-on implementation specialist: execute the delegated task within its focused scope, then verify it. You do not review or sign off on your own work. Report changed files, evidence, caveats, and next steps." \
    "$@"
}

# Reviewer / QA — cross-family GPT-5.6-Sol (big context, strong critic, browser QA
# via agent-browser). MUST get an explicit risk threshold + stop condition in its
# brief, or edge-case diligence loops forever and burns budget.
piqa() {
  command pi --model openai-codex/gpt-5.6-sol \
    --append-system-prompt "You are an independent reviewer/QA and never review your own work. Do thorough code review and, when applicable, browser QA via agent-browser (screenshots, repro). Report findings by severity. Honor the risk threshold and stop condition in your brief: once met, STOP and report — do not keep surfacing lower-severity edge cases." \
    "$@"
}
