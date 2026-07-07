# Contributing Guide

This project is organized for group collaboration. Use the rules below so changes stay easy to review and merge.

## Branch Workflow

1. Start from the latest `main` branch.
2. Create one branch per task.
3. Keep branch names descriptive, such as `feature/location-panel` or `fix/history-chart`.
4. Open a pull request when the task is complete.

## Code Rules

- Keep changes focused on one feature or bug.
- Run `flutter format .` before pushing.
- Run `flutter analyze` and fix warnings when possible.
- Do not mix firmware and Flutter UI changes in the same PR unless they depend on each other.

## Pull Request Checklist

- The app still runs on the target device or emulator.
- The change has been tested locally.
- Any new setup steps are documented.
- Screenshots are included for visible UI changes.

## Team Notes

- Use the README to document the overall setup.
- Use issues or task cards to split work between teammates.
- Review Firebase keys and hardware secrets before sharing the repo publicly.