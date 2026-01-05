# Desktop Engineering Clean Coding (12 Weeks)

This repository is a **hands-on training program** for Windows desktop engineers who write PowerShell automation for **GPO / Intune / endpoint management**.

It is designed for:
- PowerShell **5.1**
- Engineers with **limited coding experience**
- Real-world **production safety**, not academic programming

---

## What This Repo Teaches

Over 12 weeks, engineers learn how to write PowerShell scripts that are:

- ✅ Readable under incident pressure
- ✅ Safe to run at scale
- ✅ Defensive against bad input and bad data
- ✅ Idempotent (safe to re-run)
- ✅ Observable through clear logging
- ✅ Structured like production code

This is **clean coding for desktop engineering**, not software development theory.

---

## Repo Structure

```
.
├── common/
│   └── MockGraph/          # Simulated Microsoft Graph / Intune layer
├── week01-*/               # One folder per week
│   ├── starter.ps1         # Clean baseline
│   ├── broken.ps1          # Intentionally unsafe version
│   ├── README.md           # Exercise instructions
│   ├── data/               # Mock device data (safe)
│   └── config/             # Config files (weeks 10 & 12)
└── Facilitator Notes – Desktop Engineering Clean Coding (12 Weeks).md
```

---

## How to Use This Repo (Team Members)

1. Clone the repo
2. Open the current week’s folder
3. Run the **starter** or **broken** script:
   ```powershell
   powershell.exe -ExecutionPolicy Bypass -File .\starter.ps1
   ```
4. Refactor during the session
5. Discuss tradeoffs as a team

> ⚠️ Scripts are **safe** and do NOT modify real devices.

---

## How to Use This Repo (Facilitator)

- Use the **Facilitator Notes** document for guidance
- Keep sessions time-boxed (≈60 minutes)
- Focus discussion on **production risk**
- Stop “over-engineering” early

The goal is **confidence and safety**, not perfection.

---

## MockGraph Module

All Graph / Intune calls are simulated using the `MockGraph` module:

```powershell
Import-Module ..\common\MockGraph\MockGraph.psd1 -Force
```

It supports:
- Success responses
- 401 Unauthorized
- 429 Throttling (with Retry-After)
- Empty responses
- Transient failures (503)

This mirrors real Graph behavior without tenant risk.

---

## Ground Rules for Sessions

- Readability > cleverness
- Safety > speed
- Scripts should **refuse** to run when unsafe
- Logging is part of the product
- If this ran on 10,000 devices, it must still be safe

---

## End Goal

By the end of week 12, engineers should be comfortable saying:

> “I trust this script to run in production.”

That mindset is the real deliverable.

---

## License / Usage

Internal training use.  
No external dependencies.  
No tenant access required.


---

## PR Checklist
For any changes, reviewers should use `PR_CHECKLIST.md`.


---

## Expected “After” Examples
Each week folder includes an `after.ps1` showing a reasonable end-state solution for that session.
