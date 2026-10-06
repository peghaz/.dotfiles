# CLI Applications

Apply this reference when building or changing a Python command-line application.

## CLI Structure

- Use Typer for commands, arguments, options, validation, help text, and command groups.
- Keep command functions thin. They should translate CLI input into calls to typed application or service code rather than contain business logic.
- Keep reusable application behavior independent of Typer so it can be tested and called without invoking the CLI.
- Give failures clear messages and meaningful exit codes. Do not expose tracebacks for expected user errors unless a debug mode was explicitly requested.

## Rich Output

- Use Rich for human-facing tables, panels, progress, status messages, errors, and readable JSON output.
- Use `Console.print_json()` or an equivalent Rich JSON renderer when JSON is intended for interactive human inspection.
- Move substantial terminal formatting into a dedicated `reporting.py` or `presentation.py` module. Commands should prepare data and delegate rendering.
- Keep machine-readable output separate from decorative terminal output. A `--json` or equivalent automation mode must emit valid JSON without explanatory text, progress bars, or ANSI styling.
- Let Rich adapt styling when output is redirected; do not force terminal color codes into files or pipelines.

## Verification

- Test command behavior with Typer's test runner, including help text, invalid input, exit codes, and machine-readable output.
- Test application logic independently from the CLI wrapper.
