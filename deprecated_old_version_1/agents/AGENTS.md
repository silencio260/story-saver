# Agent Operating Rules

## Tests Are Opt-In

- Do not create new test files unless the user explicitly asks for tests.
- Do not run `flutter test`, `flutter analyze`, builds, or other long validation suites unless the user explicitly asks for that command.
- If verification would normally be useful, state the exact command you would run and wait for the user to ask for it.
- For quick sanity checks, prefer static inspection and small targeted reads over running project-wide commands.
