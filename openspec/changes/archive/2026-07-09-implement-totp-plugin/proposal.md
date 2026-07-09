## Why

現在 `fish-totp` はアイデア段階（`idea.md`）のみで、実際に fisher でインストールできる fish shell 拡張機能としては何も実装されていない。`oathtool` をラップした `totp <site>` コマンドと、シークレットファイルに基づく動的な補完を提供する最小構成のプラグインを作り、fisher 経由でインストール可能にする。

## What Changes

- fisher プラグインの標準レイアウト（`functions/`, `completions/`, `conf.d/`）でリポジトリを構成する
- `functions/totp.fish`: `totp <site>` を実行すると `$TOTP_DIR/<site>` から Base32 シークレットを読み、`oathtool --totp --base32` で TOTP を生成して出力する
  - `oathtool` が見つからない場合は、インストールを促す分かりやすいメッセージを表示して終了する
  - サイトが存在しない場合、シークレットファイルが読めない場合はエラーメッセージを表示する
- `completions/totp.fish`: `$TOTP_DIR` 配下のファイル名一覧から動的に補完候補を生成する（`totp <TAB>`）
- `conf.d/fish-totp.fish`: `TOTP_DIR` 環境変数が未設定なら `~/.config/totp` をデフォルトとして設定する（プラグイン読み込み時に `oathtool` の存在チェックは行わない）
- `README.md` の Installation セクションを `fisher install <owner>/fish-totp` に更新する

## Capabilities

### New Capabilities
- `totp-generation`: `totp <site>` によるTOTP生成、`TOTP_DIR` 配下のシークレットファイル規約、動的な補完、`oathtool` 欠如時・不正サイト指定時のエラーハンドリングを含む、このプラグインの中核機能

### Modified Capabilities
(none — 新規プロジェクトのため既存スペックはない)

## Impact

- 影響コード: 新規ファイルのみ（`functions/totp.fish`, `completions/totp.fish`, `conf.d/fish-totp.fish`, `README.md`）
- 依存: `oathtool`（実行時必須、インストール手順には含めない）、fish shell、fisher（配布経路）
- 対象外（Non-goals）: TOTP アルゴリズム自体の実装、秘密鍵の暗号化、認証情報の同期、GUI、および `idea.md` の Future Ideas（`totp ls/add/remove/show/copy/qr/import` などのサブコマンド、`pass`/`gopass`/1Password 連携、`fzf` 連携、残り有効時間表示）
