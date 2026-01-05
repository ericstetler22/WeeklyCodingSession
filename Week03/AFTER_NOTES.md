# Expected "After" Example

This file represents a reasonable "end of session" outcome.

## Key improvements
- Uses the shared MockGraph module rather than duplicating mock logic.
- Fails fast on empty results and surfaces clear error messages.
- Returns non-zero exit code on failure for automation/CI friendliness.
