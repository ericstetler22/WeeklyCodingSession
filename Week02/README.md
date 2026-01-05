# Week 2 — Guardrails First

**Principle:** Validate inputs before doing damage.

## Goal
Add parameter validation to prevent unsafe runs (empty input, wildcard, mass targets).

## Run
`powershell.exe -ExecutionPolicy Bypass -File .\starter.ps1 -DeviceNames NYC-LT-001,NYC-LT-002`

## Output
Writes to `output\\actions.log`.
