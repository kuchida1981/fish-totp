## ADDED Requirements

### Requirement: CI Trigger
The system SHALL run a GitHub Actions workflow automatically on `push` and `pull_request` events.

#### Scenario: Push triggers the workflow
- **WHEN** a commit is pushed to the repository
- **THEN** the CI workflow starts automatically

#### Scenario: Pull request triggers the workflow
- **WHEN** a pull request is opened or updated
- **THEN** the CI workflow starts automatically

### Requirement: CI Environment Setup
The CI workflow SHALL install fish (via the official fish-shell PPA), `jq`, `oathtool`, `python3`, and `fisher` before running tests.

#### Scenario: Dependencies available before tests run
- **WHEN** the CI job reaches the test steps
- **THEN** `fish`, `jq`, `oathtool`, `python3`, and `fisher` are all installed and available on `PATH`

### Requirement: CI Runs Install and Command Tests
The CI workflow SHALL run both the `fisher install .` verification and the `test/run.fish` command test suite, and SHALL fail the job if either fails.

#### Scenario: Install verification failure fails the job
- **WHEN** `fisher install .` fails during the CI job
- **THEN** the CI job is marked as failed and the command test suite step does not report success

#### Scenario: Command test failure fails the job
- **WHEN** `test/run.fish` exits with a non-zero status during the CI job
- **THEN** the CI job is marked as failed
