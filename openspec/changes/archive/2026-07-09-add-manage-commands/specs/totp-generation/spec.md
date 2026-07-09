## MODIFIED Requirements

### Requirement: TOTP コード生成
`totp <site>` を実行すると、システムは `$TOTP_DIR/<site>` に保存された JSON から `jq` を用いて `secret` フィールド（Base32 エンコード済み）を取り出し、`oathtool --totp --base32` を用いて6桁の TOTP コードを標準出力に出力しなければならない（SHALL）。JSON に含まれる `algorithm`・`digits`・`period` フィールドはコード生成には反映せず、生成は常に SHA1・6桁・30秒で行わなければならない（SHALL）。

#### Scenario: 登録済みサイトの TOTP を生成する
- **WHEN** ユーザーが `totp github` を実行し、`$TOTP_DIR/github` に `secret` フィールドを含む有効な JSON が存在する
- **THEN** システムは標準出力に6桁の TOTP コードを出力する

### Requirement: シークレットの保存規約
システムは、`$TOTP_DIR` 配下の1ファイル = 1サイトという規約でシークレットを管理しなければならない（SHALL）。各ファイルはファイル名をサイト名とし、内容には `secret`・`issuer`・`account`・`algorithm`・`digits`・`period` を持つ JSON オブジェクトを格納する。`secret` フィールドには Base32 エンコードされたシークレットを格納しなければならない（SHALL）。

#### Scenario: 新しいサイトを追加する
- **WHEN** ユーザーが `$TOTP_DIR/slack` というファイルを作成し、`secret` フィールドを含む JSON オブジェクトを書き込む
- **THEN** `totp slack` はそのファイルの `secret` フィールドを読み取って TOTP コードを生成できる

## ADDED Requirements

### Requirement: シークレットファイルの JSON が不正な場合のエラー
システムは、対象サイトのシークレットファイルが存在し読み取り可能だが、内容が妥当な JSON として解析できない場合、エラーメッセージを表示し、TOTP コードは出力してはならない（SHALL NOT）。

#### Scenario: JSON として解析できないシークレットファイル
- **WHEN** ユーザーが `totp github` を実行し、`$TOTP_DIR/github` は存在し読み取り可能だが内容が不正な JSON である
- **THEN** システムはエラーメッセージを表示し、TOTP コードは出力しない

### Requirement: jq 欠如時のエラー
システムは `totp <site>` の実行時に `jq` コマンドの存在を確認しなければならない（SHALL）。`jq` が見つからない場合、システムは `jq` のインストールを促す独自のエラーメッセージを表示し、TOTP コードは出力してはならない（SHALL NOT）。このチェックはプラグイン読み込み時ではなく、コマンド実行時に行わなければならない（SHALL）。

#### Scenario: jq が未インストールの環境で totp を実行する
- **WHEN** `jq` コマンドが `PATH` 上に存在しない状態で `totp github` を実行する
- **THEN** システムは `jq` のインストールを促すメッセージを表示し、TOTP コードは出力しない

#### Scenario: jq 未インストールでもプラグイン読み込みは失敗しない
- **WHEN** `jq` コマンドが `PATH` 上に存在しない状態で fish シェルを起動する
- **THEN** プラグインの読み込みはエラーにならず、`totp` コマンドと補完は正常に登録される
