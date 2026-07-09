## ADDED Requirements

### Requirement: リリースワークフローのトリガーと入力
リポジトリは `workflow_dispatch` トリガーを持つリリース用 GitHub Actions ワークフロー（`.github/workflows/release.yml`）を持たなければならない（SHALL）。このワークフローは `version` という名前の必須文字列入力を受け取らなければならない（SHALL）。

#### Scenario: 手動でリリースワークフローを実行する
- **WHEN** メンテナが GitHub Actions の UI または `gh workflow run` から `version` 入力に `0.2.0` を指定してワークフローを実行する
- **THEN** ワークフローが起動し、後続のバリデーション・テスト・バージョン反映・タグ作成・Release作成のステップが実行される

### Requirement: バージョン入力のバリデーション
ワークフローは `version` 入力値が semver 形式（`X.Y.Z`、数字のみ、`v` などのプレフィックスを含まない）であることを検証しなければならない（SHALL）。形式に一致しない場合、ワークフローは後続のステップを実行せず失敗しなければならない（SHALL）。

#### Scenario: 不正な形式のバージョンを指定する
- **WHEN** メンテナが `version` 入力に `v0.2.0` または `0.2` のような semver 形式に一致しない値を指定して実行する
- **THEN** ワークフローはバリデーションステップで失敗し、バージョン反映・タグ作成は行われない

### Requirement: main ブランチ限定の実行
ワークフローは、実行対象が `main` ブランチでない場合に失敗しなければならない（SHALL）。

#### Scenario: main 以外のブランチから実行しようとする
- **WHEN** メンテナが `main` 以外のブランチを対象にワークフローを実行する
- **THEN** ワークフローはブランチガードのステップで失敗し、後続のステップは実行されない

### Requirement: リリース前のテスト実行
ワークフローは、バージョン反映・タグ作成を行う前に既存のテストスイートを実行しなければならない（SHALL）。テストが失敗した場合、ワークフローはバージョン反映・タグ作成・Release作成を行ってはならない（SHALL NOT）。

#### Scenario: テストが失敗する
- **WHEN** リリース対象の commit でテストスイートが失敗する
- **THEN** ワークフローはその時点で中断し、`TOTP_VERSION` の書き換え・コミット・タグ作成・Release作成のいずれも行われない

### Requirement: バージョン反映とタグ作成の順序
ワークフローは、`conf.d/fish-totp.fish` の `TOTP_VERSION` を `version` 入力値に書き換えてコミットし、そのコミットに対して `version` 入力値と同一の文字列（`v` プレフィックスなし）を tag 名として作成しなければならない（SHALL）。tag は必ずバージョン反映コミットの作成後に、当該コミットに対して作成されなければならない（SHALL）。

#### Scenario: バージョン反映後にタグが作成される
- **WHEN** ワークフローが `version` 入力値 `0.2.0` でリリースを実行する
- **THEN** `conf.d/fish-totp.fish` の `TOTP_VERSION` が `0.2.0` に書き換えられたコミットが作成され、そのコミットに対して tag `0.2.0` が作成される

#### Scenario: タグ指定でインストールしたユーザーのバージョン表示が一致する
- **WHEN** ユーザーが `fisher install owner/fish-totp@0.2.0` で特定バージョンをインストールする
- **THEN** `totp version` の出力は `fish-totp 0.2.0` であり、インストールした tag と一致する

### Requirement: GitHub Release の作成
ワークフローは、作成した tag を対象に `--generate-notes` オプションを用いて GitHub Release を作成しなければならない（SHALL）。リリースノートの手動記述は要求しない。

#### Scenario: Release が自動生成ノート付きで作成される
- **WHEN** tag `0.2.0` が作成される
- **THEN** GitHub Release `0.2.0` が、直近の tag からの変更を要約した自動生成ノート付きで作成される
