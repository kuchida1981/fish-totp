# fish-totp

[![CI](https://github.com/kuchida1981/fish-totp/actions/workflows/ci.yml/badge.svg)](https://github.com/kuchida1981/fish-totp/actions/workflows/ci.yml)

`oathtool` を利用して TOTP (Time-based One-Time Password) を生成するための Fish Shell Extension。

## Features

- `totp <site>` で TOTP を生成
- サイト名の補完に対応
- サイトの追加はファイルを1つ配置するだけ
- シンプルな構成
- `oathtool` を利用するため独自実装不要

## Requirements

- fish shell
- oathtool
- jq
- python3 (URIから追加する場合のみ)

## Installation

```sh
fisher install <owner>/fish-totp
```

## Usage

```console
$ totp github
123456
```

補完:

```console
$ totp <TAB>
add
remove
ls
show
aws
github
google
slack
```

### 管理コマンドの使用例

- **サイトの追加（URI から）** (issuer が自動的にサイト名になります)
  ```console
  $ totp add "otpauth://totp/GitHub:user@example.com?secret=JBSWY3DPEHPK3PXP&issuer=GitHub"
  ```

- **サイトの追加（シークレット単体）** (`--name` オプションが必須です)
  ```console
  $ totp add JBSWY3DPEHPK3PXP --name slack
  ```

- **サイト名一覧の表示**
  ```console
  $ totp ls
  github
  slack
  ```

- **登録されているサイトの詳細表示** (シークレットを含む全メタデータを表示します)
  ```console
  $ totp show github
  {
    "secret": "JBSWY3DPEHPK3PXP",
    "issuer": "GitHub",
    "account": "user@example.com",
    "algorithm": "SHA1",
    "digits": 6,
    "period": 30
  }
  ```

- **サイトの削除** (確認なしで即座に削除されます)
  ```console
  $ totp remove slack
  ```

## Secret Storage

秘密鍵はディレクトリにファイルとして保存する。

```
~/.config/totp/
├── aws
├── github
├── google
└── slack
```

各ファイルには `secret`・`issuer`・`account`・`algorithm`・`digits`・`period` を持つ JSON 形式で保存する。

例:

```json
{
  "secret": "JBSWY3DPEHPK3PXP",
  "issuer": "GitHub",
  "account": "byebyeearthjpn@gmail.com",
  "algorithm": "SHA1",
  "digits": 6,
  "period": 30
}
```

## Command Behavior

```
totp <site>
```

内部では次のコマンドを実行する。

```sh
oathtool --totp --base32 "$(jq -r .secret ~/.config/totp/<site>)"
```

## Completion

補完候補は `~/.config/totp/` 配下のファイル名から動的に生成する。

例:

```console
$ totp <TAB>
aws
github
google
slack
```

新しいサイトを追加すると自動的に補完対象となる。

## Error Handling

存在しないサイトを指定した場合:

```console
$ totp unknown
unknown site: unknown
```

秘密鍵ファイルが読めない場合もエラーとする。

## Future Ideas

- `totp copy`（クリップボードへコピー）
- `totp qr`（QRコードから登録）
- `totp import`（otpauth:// URI のインポート）
- `pass`、`gopass`、`1Password CLI` などとの連携
- `fzf` によるインタラクティブ選択
- 残り有効時間の表示

## Testing

以下のコマンドでテストを実行できます。

```sh
fish test/run.fish
```

### 必要な依存ツール

- `fish`
- `jq`
- `oathtool`
- `python3` （`totp add` の otpauth URI テストで使用）

※ `fisher install .` のインストール検証テストは `fisher` が導入済みの場合のみ実行され、無い場合は自動的にスキップされます。

## Versioning

`totp version` コマンドでバージョンを表示できる。

```console
$ totp version
fish-totp 0.1.0
```

### バージョニング規約

- バージョンは Semantic Versioning (semver, `X.Y.Z`) 形式で管理する。
- Git タグにはプレフィックス（`v` など）を付けない。タグ名は `TOTP_VERSION` の値と完全に一致させる（例: `0.2.0`。`v0.2.0` ではない）。
- `TOTP_VERSION` 変数は `conf.d/fish-totp.fish` に定義されており、プラグインロード時に設定される。

### リリース手順

- リリースは GitHub Actions の `workflow_dispatch`（`.github/workflows/release.yml`）を手動実行して行う。
- 実行時に `version` 入力（例: `0.2.0`）を指定する。
- ワークフローは `main` ブランチ限定で実行され、テスト実行、`TOTP_VERSION` 更新・コミット、タグ作成、GitHub Release 作成（`--generate-notes`）を自動で行う。
- 実行には該当リポジトリへの書き込み権限（`contents: write` を許可する権限を持つユーザー）が必要である。

## Non-goals

- TOTP アルゴリズムの実装
- 秘密鍵の暗号化
- 認証情報の同期
- GUI

## License

MIT
