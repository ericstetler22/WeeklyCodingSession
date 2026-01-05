# Expected "After" Example

This file represents a reasonable "end of session" outcome.

## Key improvements
- Checks current state before writing (true idempotency).
- Supports DryRun and logs intended actions.
- Uses per-device state files so it’s safe for training.
