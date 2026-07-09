## Why

現在の fish-totp は `$TOTP_DIR` にシークレットファイルを手動で配置する運用しかできず、サイトの追加・削除・一覧確認はすべてファイルシステム操作を直接行う必要がある。README の Future Ideas に挙げられている `ls`/`add`/`remove`/`show` を実装し、`otpauth://` URI からの登録にも対応することで、TOTP シークレットの登録・管理を `totp` コマンド単体で完結させる。

## What Changes

- `totp add` を追加: `otpauth://` URI、または Base32 シークレット文字列単体のいずれかを受け付けて新しいサイトを登録する
  - シークレット単体渡しの場合は `--name` オプションが必須（省略時はエラー）
  - URI 渡しの場合は URI 中のメタデータ（issuer、account、secret、algorithm、digits、period）を抽出して保存し、`--name` を省略した場合は `issuer` をサイト名として自動採用する
  - `--name`/`--issuer`/`--account`/`--algorithm`/`--digits`/`--period` オプション引数は、URI から抽出した値より常に優先される
  - 登録先ファイルが既に存在する場合は上書きせずエラーにする
- `totp remove <site>` を追加: 確認プロンプトなしで即座に `$TOTP_DIR/<site>` を削除する
- `totp ls` を追加: 登録済みサイト名の一覧を表示する
- `totp show <site>` を追加: 指定したサイトの全メタデータ（secret を含む）を表示する
- **BREAKING**: シークレットファイルの保存形式をプレーンテキスト（Base32文字列のみ）から JSON（`secret`/`issuer`/`account`/`algorithm`/`digits`/`period` を持つオブジェクト）に変更する。ファイル名（サイト名）の規約自体は変更しない
- **BREAKING**: `totp <site>` のコード生成ロジックを、ファイルを直接 `oathtool` に渡す方式から `jq -r .secret` で JSON から secret を取り出す方式に変更する。`algorithm`/`digits`/`period` メタデータは保存のみ行い、生成時の `oathtool` 呼び出しは引き続き SHA1/6桁/30秒固定とする（尊重は将来のスコープ）

## Capabilities

### New Capabilities
- `secret-management`: `totp add`/`totp remove`/`totp ls`/`totp show` による TOTP シークレットの登録・削除・一覧・詳細表示、および otpauth:// URI パースと JSON ストレージ形式の管理

### Modified Capabilities
- `totp-generation`: シークレットの保存規約を JSON 形式に変更し、`totp <site>` の実装が `jq` を用いて secret フィールドを取り出すように変更する

## Impact

- `functions/totp.fish`: secret 取得ロジックを `jq -r .secret` 経由に変更
- `functions/` に `totp_add.fish` / `totp_remove.fish` / `totp_ls.fish` / `totp_show.fish`（または `totp` 内のサブコマンド分岐）を新規追加
- `completions/totp.fish`: `add`/`remove`/`ls`/`show` サブコマンドの補完を追加
- 新規依存: `jq`（JSON構築・パース）、`python3`（otpauth:// URI の `urllib.parse` によるパース・URLデコード）。いずれも `oathtool` と同様、コマンド実行時に存在チェックしインストールを促す
- README の Requirements・Secret Storage・Command Behavior・Future Ideas セクションを更新
- 既存の `openspec/specs/totp-generation/spec.md` を更新（破壊的変更のため、後方互換シムは設けない）
