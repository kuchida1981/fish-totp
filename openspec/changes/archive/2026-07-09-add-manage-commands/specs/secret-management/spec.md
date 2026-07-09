## ADDED Requirements

### Requirement: シークレットを otpauth:// URI から登録する
`totp add "<otpauth-uri>"` を実行すると、システムは URI をパースして `secret`・`issuer`・`account`・`algorithm`・`digits`・`period` を抽出し、`$TOTP_DIR` 配下に JSON として保存しなければならない（SHALL）。URI のクエリパラメータに `algorithm`/`digits`/`period` が含まれない場合、システムはそれぞれ `SHA1`・`6`・`30` を補完して保存しなければならない（SHALL）。

#### Scenario: otpauth URI からサイトを登録する
- **WHEN** ユーザーが `totp add "otpauth://totp/GitHub:byebyeearthjpn%40gmail.com?secret=JBSWY3DPEHPK3PXP&issuer=GitHub"` を実行する
- **THEN** システムは `$TOTP_DIR/GitHub` に `secret=JBSWY3DPEHPK3PXP`・`issuer=GitHub`・`account=byebyeearthjpn@gmail.com`・`algorithm=SHA1`・`digits=6`・`period=30` を含む JSON を書き込む

#### Scenario: URIにalgorithm/digits/periodが省略されている場合デフォルト値を補完する
- **WHEN** ユーザーが `algorithm`/`digits`/`period` クエリパラメータを含まない otpauth URI で `totp add` を実行する
- **THEN** システムは保存する JSON にそれぞれ `SHA1`・`6`・`30` を補完する

### Requirement: otpauth:// URI 渡し時のサイト名自動決定
`totp add` に otpauth:// URI を渡し、かつ `--name` オプションが省略された場合、システムは URI から抽出した `issuer` をサイト名として自動採用しなければならない（SHALL）。

#### Scenario: --name を省略してissuerがサイト名になる
- **WHEN** ユーザーが `--name` を指定せずに `issuer=GitHub` を含む otpauth URI で `totp add` を実行する
- **THEN** システムは `$TOTP_DIR/GitHub` にシークレットを保存する

### Requirement: シークレット文字列単体からの登録には --name が必須
`totp add <secret>` のように Base32 シークレット文字列単体を渡す場合、システムは `--name` オプションを必須としなければならない（SHALL）。`--name` が省略された場合、システムは対話的にサイト名を問い合わせてはならず（SHALL NOT）、エラーメッセージを表示して終了しなければならない（SHALL）。

#### Scenario: --name を指定してシークレット単体を登録する
- **WHEN** ユーザーが `totp add JBSWY3DPEHPK3PXP --name slack` を実行する
- **THEN** システムは `$TOTP_DIR/slack` に `secret=JBSWY3DPEHPK3PXP` を含む JSON を保存する（issuer/account は未設定のまま）

#### Scenario: --name を省略するとエラーになる
- **WHEN** ユーザーが `totp add JBSWY3DPEHPK3PXP` を `--name` を付けずに実行する
- **THEN** システムはサイト名が必要である旨のエラーメッセージを表示し、ファイルを作成しない

### Requirement: オプション引数によるメタデータ上書き
`totp add` に `--name`・`--issuer`・`--account`・`--algorithm`・`--digits`・`--period` のいずれかが明示的に指定された場合、システムはその値を otpauth URI から抽出した値より優先して採用しなければならない（SHALL）。

#### Scenario: --issuer で otpauth URI 由来の issuer を上書きする
- **WHEN** ユーザーが `issuer=GitHub` を含む otpauth URI に加えて `--issuer Work-GitHub` を指定して `totp add` を実行する
- **THEN** システムは保存する JSON の `issuer` を `Work-GitHub` にする

### Requirement: サイト名の妥当性検証
システムは、自動決定または明示指定されたサイト名が空文字列である場合、または `/` を含む場合、エラーメッセージを表示して `totp add` を終了しなければならない（SHALL）。

#### Scenario: issuer名に / が含まれ自動決定できない
- **WHEN** ユーザーが `--name` を省略し、`issuer` に `/` を含む otpauth URI で `totp add` を実行する
- **THEN** システムはエラーメッセージを表示し、`--name` での明示指定を促し、ファイルを作成しない

### Requirement: 登録済みサイトへの上書き防止
システムは、`totp add` で決定したサイト名のファイルが `$TOTP_DIR` に既に存在する場合、上書きせずエラーメッセージを表示して終了しなければならない（SHALL）。

#### Scenario: 既存サイト名に add しようとする
- **WHEN** ユーザーが `$TOTP_DIR/github` が既に存在する状態で `totp add ... --name github` を実行する
- **THEN** システムは既に存在する旨のエラーメッセージを表示し、既存ファイルを変更しない

### Requirement: サイトの削除
`totp remove <site>` を実行すると、システムは確認プロンプトを表示せずに `$TOTP_DIR/<site>` を即座に削除しなければならない（SHALL）。

#### Scenario: 登録済みサイトを削除する
- **WHEN** ユーザーが `$TOTP_DIR/slack` が存在する状態で `totp remove slack` を実行する
- **THEN** システムは確認を求めずに `$TOTP_DIR/slack` を削除する

#### Scenario: 存在しないサイトを削除しようとする
- **WHEN** ユーザーが `$TOTP_DIR/unknown` が存在しない状態で `totp remove unknown` を実行する
- **THEN** システムは `unknown site: unknown` エラーメッセージを表示し、異常終了する

### Requirement: サイト一覧の表示
`totp ls` を実行すると、システムは `$TOTP_DIR` 配下に登録されている全サイトの名前一覧を標準出力に出力しなければならない（SHALL）。

#### Scenario: 複数サイトが登録された状態でlsを実行する
- **WHEN** `$TOTP_DIR` に `github`・`aws`・`slack` が登録された状態で `totp ls` を実行する
- **THEN** システムは `github`・`aws`・`slack` を含むサイト名一覧を標準出力に出力する

### Requirement: サイト詳細の表示
`totp show <site>` を実行すると、システムは指定サイトの `secret`・`issuer`・`account`・`algorithm`・`digits`・`period` を含む全メタデータを標準出力に表示しなければならない（SHALL）。

#### Scenario: 登録済みサイトの詳細を表示する
- **WHEN** ユーザーが `$TOTP_DIR/github` が存在する状態で `totp show github` を実行する
- **THEN** システムは `github` の `secret` を含む全メタデータを標準出力に表示する

#### Scenario: 存在しないサイトの詳細を表示しようとする
- **WHEN** ユーザーが `$TOTP_DIR/unknown` が存在しない状態で `totp show unknown` を実行する
- **THEN** システムは `unknown site: unknown` エラーメッセージを表示し、異常終了する

### Requirement: サブコマンドの補完
システムは `totp <TAB>` の補完候補に、サイト名に加えて `add`・`remove`・`ls`・`show` のサブコマンドを含めなければならない（SHALL）。

#### Scenario: サブコマンドが補完候補に含まれる
- **WHEN** ユーザーが `totp <TAB>` を入力する
- **THEN** 補完候補一覧に `add`・`remove`・`ls`・`show` が含まれる

### Requirement: jq 欠如時のエラー
システムは `totp add`・`totp remove`・`totp ls`・`totp show` の実行時に `jq` コマンドの存在を確認しなければならない（SHALL）。`jq` が見つからない場合、システムは `jq` のインストールを促す独自のエラーメッセージを表示し、処理を中断しなければならない（SHALL）。

#### Scenario: jq が未インストールの環境で totp add を実行する
- **WHEN** `jq` コマンドが `PATH` 上に存在しない状態で `totp add JBSWY3DPEHPK3PXP --name slack` を実行する
- **THEN** システムは `jq` のインストールを促すメッセージを表示し、ファイルを作成しない

### Requirement: python3 欠如時のエラー
システムは `totp add` に otpauth:// URI が渡された場合、`python3` コマンドの存在を確認しなければならない（SHALL）。`python3` が見つからない場合、システムは `python3` のインストールを促す独自のエラーメッセージを表示し、処理を中断しなければならない（SHALL）。

#### Scenario: python3 が未インストールの環境で otpauth URI を add する
- **WHEN** `python3` コマンドが `PATH` 上に存在しない状態で `totp add "otpauth://totp/GitHub?secret=XXX&issuer=GitHub"` を実行する
- **THEN** システムは `python3` のインストールを促すメッセージを表示し、ファイルを作成しない
