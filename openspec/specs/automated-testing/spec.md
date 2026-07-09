# automated-testing

## Purpose

外部フレームワークに依存しない fish 製のアサートヘルパーとコマンド別テストファイルによる、fish-totp プラグインの自動テストスイート。`fisher install .` によるインストール検証と、`totp`/`totp add`/`totp ls`/`totp remove`/`totp show` の正常系・異常系の挙動カバレッジ、テスト間の分離、テストランナーの終了ステータスを含む。

## Requirements

### Requirement: Install Verification
The system SHALL provide an automated test that verifies `fisher install .` succeeds and that all plugin functions are loaded afterward.

#### Scenario: Functions loaded after fisher install
- **WHEN** `fisher install .` is executed against the repository working tree
- **THEN** the functions `totp`, `totp_add`, `totp_ls`, `totp_remove`, and `totp_show` are all defined and callable

### Requirement: Command Behavior Test Coverage
The system SHALL provide automated tests covering the normal and error-path behavior of `totp`, `totp add`, `totp ls`, `totp remove`, and `totp show`.

#### Scenario: totp generates a 6-digit code for a valid site
- **WHEN** `totp <site>` is executed with a valid secret file present under `TOTP_DIR`
- **THEN** the command exits successfully and stdout matches the pattern `^[0-9]{6}$`

#### Scenario: totp reports an error for an unknown site
- **WHEN** `totp <site>` is executed with a site name that has no corresponding file under `TOTP_DIR`
- **THEN** the command exits with a non-zero status and writes an `unknown site` message to stderr

#### Scenario: totp add creates a secret file from an otpauth URI
- **WHEN** `totp add "otpauth://totp/Issuer:account?secret=...&issuer=Issuer"` is executed
- **THEN** a JSON file is created under `TOTP_DIR` named after the issuer, containing the parsed `secret`, `issuer`, and `account` fields

#### Scenario: totp add requires --name when given a bare secret
- **WHEN** `totp add <secret>` is executed without an otpauth URI and without `--name`
- **THEN** the command exits with a non-zero status and reports that `--name` is required

#### Scenario: totp add refuses to overwrite an existing site
- **WHEN** `totp add` is executed with a name that already has a file under `TOTP_DIR`
- **THEN** the command exits with a non-zero status and does not modify the existing file

#### Scenario: totp ls lists only files under TOTP_DIR
- **WHEN** `totp ls` is executed with one or more secret files present under `TOTP_DIR`
- **THEN** stdout lists exactly the site names present under `TOTP_DIR`, one per line

#### Scenario: totp remove deletes an existing site
- **WHEN** `totp remove <site>` is executed for a site that exists under `TOTP_DIR`
- **THEN** the corresponding file is removed and the command exits successfully

#### Scenario: totp remove and totp show reject path traversal
- **WHEN** `totp remove` or `totp show` is executed with a site name containing `/`
- **THEN** the command exits with a non-zero status, reports `unknown site`, and does not access any file outside `TOTP_DIR`

#### Scenario: totp show prints formatted JSON for an existing site
- **WHEN** `totp show <site>` is executed for a site that exists under `TOTP_DIR`
- **THEN** stdout contains the formatted JSON contents of that site's secret file

#### Scenario: Commands report missing dependencies
- **WHEN** `jq`, `oathtool`, or `python3` is not available on `PATH` and a command that depends on it is executed
- **THEN** the command exits with a non-zero status and writes a message identifying the missing dependency to stderr

### Requirement: Test Isolation
Each test case SHALL run against an isolated temporary `TOTP_DIR` so that test cases do not observe files created by other test cases.

#### Scenario: Independent test cases do not share state
- **WHEN** multiple test cases run in sequence within the same test run
- **THEN** no test case observes secret files created by a preceding test case

### Requirement: Test Runner Exit Status
The test runner SHALL execute all test cases and exit with a non-zero status if any assertion fails.

#### Scenario: Runner fails on any assertion failure
- **WHEN** at least one assertion in any test case fails
- **THEN** the test runner process exits with a non-zero status after reporting which assertion(s) failed
