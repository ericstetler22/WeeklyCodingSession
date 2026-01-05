# Week 1 — Readable Scripts Under Pressure

**Principle:** Code should explain itself.

## Goal
Refactor a script that loads devices from JSON, filters Windows 10, and exports a CSV.

## Run
- Starter: `powershell.exe -ExecutionPolicy Bypass -File .\starter.ps1`
- Broken:  `powershell.exe -ExecutionPolicy Bypass -File .\broken.ps1`

## What to change (during the session)
- Improve names
- Split into small functions
- Remove magic values

## Output
Creates `output\\win10_devices.csv`.
