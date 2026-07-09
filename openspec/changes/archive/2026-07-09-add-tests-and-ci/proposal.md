## Why

fish-totp には現時点で自動テストが存在せず、`totp` およびサブコマンド（`add`/`ls`/`remove`/`show`）の挙動変化や `fisher install` の破損をリグレッションとして検知できない。パストラバーサル対策や権限チェックなど過去に手動で修正した箇所も、今後の変更で再度壊れる可能性がある。GitHub リモートも設定済みのため、push のたびに自動検証する土台を今のうちに整えたい。

## What Changes

- `test/` ディレクトリに、外部フレームワークに依存しない fish 製の簡易アサートヘルパー（`assert_eq` 等）と、コマンドごとのテストファイルを追加する
- `fisher install .` によるインストール成功（`totp`/`totp_add`/`totp_ls`/`totp_remove`/`totp_show` 関数のロード）を検証するテストを追加する
- 各コマンドの正常系・異常系（存在しない site、パストラバーサル、`jq`/`oathtool`/`python3` 欠如、上書き防止など）をカバーするテストを追加する
- GitHub Actions ワークフロー（`.github/workflows/ci.yml`）を追加し、push/PR 時に fish 公式 PPA で最新版 fish を導入した上でインストールテストとコマンドテストを自動実行する
- 動作確認用 `Dockerfile`（現状 untracked）を git 管理下に置き、`fisher install .` 相当のステップを追加して手元確認できる状態に仕上げる

## Capabilities

### New Capabilities
- `automated-testing`: `test/` 配下のアサートヘルパーと各コマンドの正常系・異常系テストスイート
- `continuous-integration`: GitHub Actions によるインストール検証とテスト自動実行

### Modified Capabilities
(none — 既存の `totp-generation` / `secret-management` の要件は変更しない。テスト対象として参照するのみ)

## Impact

- 追加: `test/run.fish`, `test/helpers.fish`, `test/totp.test.fish`, `test/totp_add.test.fish`, `test/totp_ls.test.fish`, `test/totp_remove.test.fish`, `test/totp_show.test.fish`, `.github/workflows/ci.yml`
- git 管理下に追加: `Dockerfile`（内容を修正）
- 既存の `functions/`・`completions/`・`conf.d/` のコードは変更しない（テスト対象として参照のみ）
- 新規の実行時依存追加なし（CI 環境にのみ `fish`/`jq`/`oathtool`/`python3`/`fisher` をインストール）
