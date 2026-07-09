## 1. `totp version` サブコマンド

- [x] 1.1 `conf.d/fish-totp.fish` に `TOTP_VERSION` のデフォルト設定を追加する（`TOTP_DIR` と同じパターンで `set -q` チェック後に `set -g TOTP_VERSION "0.1.0"`）
- [x] 1.2 `functions/totp_version.fish` を新規作成し、`fish-totp $TOTP_VERSION` を標準出力に出力する
- [x] 1.3 `functions/totp.fish` のディスパッチ `switch` に `version` を追加する（`case add remove ls show version`）
- [x] 1.4 `completions/totp.fish` の第一引数の補完候補に `version` を追加する

## 2. リリースワークフロー

- [x] 2.1 `.github/workflows/release.yml` を新規作成する: `workflow_dispatch` トリガー、`version` 文字列入力（必須）、`permissions: contents: write`
- [x] 2.2 ブランチガードステップを追加する（`github.ref` が `refs/heads/main` でなければ失敗させる）
- [x] 2.3 `version` 入力値の semver (`X.Y.Z`) バリデーションステップを追加する（不一致なら失敗）
- [x] 2.4 既存テストスイート（`test/run.fish` 相当、既存 CI の実行手順を参考）を実行するステップを追加する
- [x] 2.5 `conf.d/fish-totp.fish` の `TOTP_VERSION` を `version` 入力値に書き換え、`chore: release <version>` としてコミット・push するステップを追加する
- [x] 2.6 直前のコミットに対して `v` プレフィックスなしの tag（`<version>` そのもの）を作成し push するステップを追加する
- [x] 2.7 `gh release create <version> --generate-notes` で GitHub Release を作成するステップを追加する

## 3. ドキュメント

- [x] 3.1 README に `totp version` の使用例を追記する
- [x] 3.2 README にバージョニング規約（semver、tag に `v` プレフィックスを付けない旨）を明記する
- [x] 3.3 README にリリース手順（`workflow_dispatch` を手動実行する旨、必要な権限）を追記する

## 4. 動作確認

- [x] 4.1 `totp version` がローカルで `fish-totp 0.1.0` を出力することを確認する
- [x] 4.2 `totp <TAB>` の補完候補に `version` が含まれることを確認する
- [x] 4.3 既存の `add`/`remove`/`ls`/`show`・裸の `totp <site>` の挙動に影響がないことをテストスイートで確認する
