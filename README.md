# fish-totp

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
aws
github
google
slack
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

各ファイルには Base32 エンコードされた秘密鍵のみを記述する。

例:

```
JBSWY3DPEHPK3PXP
```

## Command Behavior

```
totp <site>
```

内部では次のコマンドを実行する。

```sh
oathtool --totp --base32 "$(cat ~/.config/totp/<site>)"
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

- `totp ls`
- `totp add`
- `totp remove`
- `totp show`（サイト一覧）
- `totp copy`（クリップボードへコピー）
- `totp qr`（QRコードから登録）
- `totp import`（otpauth:// URI のインポート）
- `TOTP_DIR` 環境変数による保存先変更
- `pass`、`gopass`、`1Password CLI` などとの連携
- `fzf` によるインタラクティブ選択
- 残り有効時間の表示

## Non-goals

- TOTP アルゴリズムの実装
- 秘密鍵の暗号化
- 認証情報の同期
- GUI

## License

MIT
