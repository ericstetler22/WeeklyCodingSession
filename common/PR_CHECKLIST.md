# PR Checklist – Desktop Engineering Automation (PowerShell 5.1)

Use this checklist for any script changes in this repo (and ideally in your real automation repos).

## 1) Safety & Guardrails
- [ ] Script refuses unsafe input (empty lists, wildcards, “all devices” by accident)
- [ ] Defaults are safe (no destructive behavior by default)
- [ ] Parameter validation is present and meaningful (`[ValidateSet]`, `[ValidateNotNullOrEmpty]`, etc.)
- [ ] `-DryRun` / `-WhatIf` behavior exists when changes are applied (or a clear equivalent)

## 2) Readability
- [ ] Variables and functions are named for **intent** (not single letters or unclear abbreviations)
- [ ] Script reads top-to-bottom like a story (minimal nesting, early returns where helpful)
- [ ] No function is doing “everything” (query/decision/action/logging separated)

## 3) Failure Behavior
- [ ] Errors are not swallowed (no empty `catch {}` blocks)
- [ ] Failure messages explain **what failed** and **what to do next**
- [ ] Script exits/returns in a way that CI or calling systems can detect failure (non-zero exit or thrown error)

## 4) Logging & Observability
- [ ] Logs include: timestamp, device/context, action, and result
- [ ] Logs can reconstruct a run timeline (start/end + per-target result)
- [ ] “Success” messages include context (what was changed / verified)

## 5) Idempotency & Desired State
- [ ] Script checks current state before applying changes
- [ ] Re-running the script produces “no change required” when already compliant
- [ ] Changes are scoped per-device and predictable

## 6) Data Handling
- [ ] External data is treated as untrusted (null checks, required fields validated)
- [ ] Missing/invalid records are skipped safely with a logged reason (or script stops intentionally if high-risk)
- [ ] No assumptions about response shape without validation

## 7) Config Over Code
- [ ] Magic values are avoided (moved to config/constants with clear names)
- [ ] Config files are validated on load (required fields, ranges)
- [ ] Behavior changes should not require code edits when feasible

## 8) Style & Maintainability
- [ ] Uses `Set-StrictMode -Version Latest` and a deliberate `$ErrorActionPreference`
- [ ] Avoids duplicated filters/logic (extract helpers)
- [ ] No secrets, tokens, tenant IDs, or real endpoints committed

---

## Reviewer Prompts (use these in the PR conversation)
- “If this ran on 10,000 devices, what’s the worst-case outcome?”
- “What’s the failure mode and how would we detect it?”
- “Can a new engineer understand this in 60 seconds?”
- “Is it safe to run twice?”
