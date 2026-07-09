## Why

fish-totp には現在バージョンを識別する仕組みが一切ない（`VERSION` ファイル・git tag・`--version` 相当のコマンドいずれも未整備）。利用者が `fisher install owner/fish-totp@<version>` のようにバージョンを指定してインストール・アップデートする際に、実際にどのバージョンが入っているかを確認する手段がなく、バグ報告や動作確認の際に支障がある。また、リリースのたびに手作業でバージョンとタグを管理すると、両者がズレるリスクがある。

## What Changes

- `totp version` サブコマンドを追加する（既存の `add`/`remove`/`ls`/`show` と同じディスパッチパターン）。`fish-totp 0.1.0` の形式で標準出力に出力する。
- `conf.d/fish-totp.fish` にプラグインロード時のデフォルト変数として `TOTP_VERSION`（初版 `0.1.0`）を設定する。`totp version` はこの値を参照する。
- `completions/totp.fish` の補完候補に `version` を追加する。
- `.github/workflows/release.yml` を新設し、`workflow_dispatch`（`version` 入力、semver 形式・`v` プレフィックスなし）で以下を1トランザクションとして実行するリリース自動化を導入する:
  1. `main` ブランチ限定で実行するブランチガード
  2. `version` 入力値の semver (`X.Y.Z`) バリデーション
  3. 既存テストスイート（`test/run.fish` 相当）の実行、失敗時は中断
  4. `conf.d/fish-totp.fish` の `TOTP_VERSION` を入力値へ書き換えて `chore: release X.Y.Z` としてコミット・push
  5. そのコミットに対して `v` プレフィックスなしのタグ（例: `0.2.0`）を作成・push
  6. `gh release create --generate-notes` で GitHub Release を作成
- README にバージョニング規約（semver・タグにプレフィックスを付けない）、`totp version` の使用例、リリース手順（`workflow_dispatch` の手動実行）を追記する。

## Capabilities

### New Capabilities
- `version-command`: `totp version` サブコマンドの出力仕様と、バージョン情報源としての `TOTP_VERSION` デフォルト設定を扱う。
- `release-management`: リリース時にタグと `TOTP_VERSION` の値を一致させるための GitHub Actions ワークフロー（`workflow_dispatch` によるバージョン更新・タグ作成・Release作成の一連の自動化）を扱う。

### Modified Capabilities
（既存 capability の要件変更はなし）

## Impact

- 影響コード: `functions/totp.fish`（ディスパッチに `version` を追加）、新規 `functions/totp_version.fish`、`completions/totp.fish`、`conf.d/fish-totp.fish`
- 新規ファイル: `.github/workflows/release.yml`
- ドキュメント: `README.md`
- 既存の `add`/`remove`/`ls`/`show` の挙動・既存 CI ワークフロー（`ci.yml`）への影響なし
