# Week 3 — Fail Fast, Never Silent

**Principle:** Errors are part of the design.

## Goal
Handle simulated Graph failures (401, 429, empty) using try/catch and clear exit behavior.

## Run
`powershell.exe -ExecutionPolicy Bypass -File .\starter.ps1 -Mode throttle`
Modes: `success`, `unauthorized`, `throttle`, `empty`
