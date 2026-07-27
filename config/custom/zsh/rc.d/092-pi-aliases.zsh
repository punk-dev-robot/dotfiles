#!/bin/zsh
##
# Pi coding-agent session launchers — multi-agent orchestration roles.
#
# Design: docs/plans/2026-07-27-pi-multi-agent-orchestration-design.md
# Runbook: docs/reference/agent-epic-runbook.md
#
# Pattern (borrowed from disler/fusion-harness): models + thinking live in the
# tier registry below (env-overridable, `PI_TIER_DEEP=... pim` for a one-off);
# role prompts are dotter-managed files under ~/.config/pi/agent/prompts/.
# `command pi` bypasses any alias, so nothing recurses; functions forward "$@".
##

# ── Tier registry (cheap → expensive: haiku < sonnet < opus < fable) ──────────
: ${PI_TIER_FAST:=anthropic/claude-haiku-4-5}
: ${PI_TIER_WORKHORSE:=anthropic/claude-sonnet-5}
: ${PI_TIER_DEEP:=anthropic/claude-opus-5}
: ${PI_TIER_SOTA:=anthropic/claude-fable-5}

# Cross-family (GPT) seats — sparingly, budget-bound.
: ${PI_XFAM_CRITIC:=openai-codex/gpt-5.6-sol}    # reviewer / big-context critic
: ${PI_XFAM_DEV:=openai-codex/gpt-5.6-terra}     # cheap codegen alternate
: ${PI_XFAM_FAST:=openai-codex/gpt-5.6-luna}     # cheap recon alternate

_pi_prompts="$HOME/.config/pi/agent/prompts"

# ── Launchers ─────────────────────────────────────────────────────────────────

# Full / unrestricted escape hatch — settings default model, all tools + skills.
alias pif='command pi'

# Recon — read-only, cheapest tier, no skills.
pir() {
  command pi --model $PI_TIER_FAST --thinking low \
    --models $PI_TIER_FAST,$PI_XFAM_FAST \
    --no-skills --tools read,grep,find,ls "$@"
}

# Principal / architect — ceiling model, deep design partner.
pip() {
  command pi --model $PI_TIER_SOTA --thinking high \
    --append-system-prompt "$_pi_prompts/principal.md" "$@"
}

# Manager / orchestrator — delegation-focused; Ctrl+P alt cross-family.
pim() {
  command pi --model $PI_TIER_DEEP --thinking medium \
    --models $PI_TIER_DEEP,$PI_XFAM_CRITIC \
    --append-system-prompt "$_pi_prompts/manager.md" "$@"
}

# Dev / implementer.
pid() {
  command pi --model $PI_TIER_DEEP --thinking medium \
    --models $PI_TIER_DEEP,$PI_XFAM_DEV \
    --append-system-prompt "$_pi_prompts/implementer.md" "$@"
}

# Reviewer / QA — cross-family critic. Brief MUST carry a risk threshold +
# stop condition, or edge-case diligence loops forever and burns budget.
piqa() {
  command pi --model $PI_XFAM_CRITIC --thinking high \
    --append-system-prompt "$_pi_prompts/reviewer.md" "$@"
}

# Workflow launcher — manager + a workflow brief.
#   piw <workflow> [prompt...]   e.g. piw 2-level "Epic AGI-5099: ..."
#   piw                          lists available workflows
piw() {
  local wf_dir="$_pi_prompts/workflows"
  if [[ -z "$1" ]]; then
    echo "usage: piw <workflow> [prompt...]  — available:"
    command ls "$wf_dir" 2>/dev/null | sed -n 's/\.md$//p' | sed 's/^/  /'
    return 1
  fi
  local wf="$wf_dir/$1.md"
  if [[ ! -f "$wf" ]]; then
    echo "piw: no workflow '$1' in $wf_dir" >&2
    return 1
  fi
  shift
  command pi --model $PI_TIER_DEEP --thinking medium \
    --models $PI_TIER_DEEP,$PI_XFAM_CRITIC \
    --append-system-prompt "$_pi_prompts/manager.md" \
    --append-system-prompt "$wf" "$@"
}
