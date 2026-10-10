# testing-and-release
Inputs: Candidate and configured deployment.
Steps: Run migrations, backend tests, Flutter checks/build, dependency audit; review feature truth and backup.
Validation: No critical defects; device and provider evidence required.
Outputs: Release report and deployment checklist.
Failure handling: retain diagnostics without secrets, fix reproducible failures, mark external blockers accurately; do not fabricate success.
