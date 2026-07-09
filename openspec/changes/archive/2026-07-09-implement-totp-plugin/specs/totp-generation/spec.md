## ADDED Requirements

### Requirement: TOTP コード生成
`totp <site>` を実行すると、システムは `$TOTP_DIR/<site>` に保存された Base32 エンコード済みシークレットを読み取り、`oathtool --totp --base32` を用いて6桁の TOTP コードを標準出力に出力しなければならない（SHALL）。

#### Scenario: 登録済みサイトの TOTP を生成する
- **WHEN** ユーザーが `totp github` を実行し、`$TOTP_DIR/github` に有効な Base32 シークレットが存在する
- **THEN** システムは標準出力に6桁の TOTP コードを出力する

### Requirement: シークレットの保存規約
システムは、`$TOTP_DIR` 配下の1ファイル = 1サイトという規約でシークレットを管理しなければならない（SHALL）。各ファイルはファイル名をサイト名とし、内容には Base32 エンコードされたシークレットのみを含む。

#### Scenario: 新しいサイトを追加する
- **WHEN** ユーザーが `$TOTP_DIR/slack` というファイルを作成し、Base32 シークレットを1行だけ書き込む
- **THEN** `totp slack` はそのファイルを読み取って TOTP コードを生成できる

### Requirement: TOTP_DIR のデフォルト設定
プラグインは読み込み時に、`TOTP_DIR` 環境変数が未設定であれば `~/.config/totp` をデフォルト値として設定しなければならない（SHALL）。既に `TOTP_DIR` が設定されている場合は、その値を上書きしてはならない（SHALL NOT）。

#### Scenario: TOTP_DIR が未設定の場合にデフォルトが使われる
- **WHEN** シェル起動時に `TOTP_DIR` が設定されていない
- **THEN** プラグインは `TOTP_DIR` を `~/.config/totp` に設定する

#### Scenario: TOTP_DIR が既に設定されている場合は尊重される
- **WHEN** ユーザーが `TOTP_DIR` を独自のパスに設定した状態でシェルを起動する
- **THEN** プラグインはその値を変更せず、`totp` コマンドと補完はそのパスを参照する

### Requirement: サイト名の動的補完
システムは `totp <TAB>` の補完候補を、`$TOTP_DIR` 配下に存在するファイル名から動的に生成しなければならない（SHALL）。事前登録や別途のインデックス更新は不要でなければならない（SHALL）。

#### Scenario: 新しいサイトのファイルを追加すると即座に補完対象になる
- **WHEN** ユーザーが `$TOTP_DIR` に新しいシークレットファイル `aws` を追加した直後に `totp <TAB>` を入力する
- **THEN** 補完候補一覧に `aws` が含まれる

### Requirement: 未知のサイト指定時のエラー
システムは、指定された `<site>` に対応するファイルが `$TOTP_DIR` 配下に存在しない場合、`unknown site: <site>` というエラーメッセージを表示し、TOTP コードは出力してはならない（SHALL NOT）。

#### Scenario: 存在しないサイトを指定する
- **WHEN** ユーザーが `totp unknown` を実行し、`$TOTP_DIR/unknown` が存在しない
- **THEN** システムは `unknown site: unknown` を出力し、TOTP コードは出力しない

### Requirement: シークレットファイルが読めない場合のエラー
システムは、対象サイトのシークレットファイルが存在するが読み取れない場合（権限不足など）、エラーメッセージを表示し、TOTP コードは出力してはならない（SHALL NOT）。

#### Scenario: 読み取り権限のないシークレットファイル
- **WHEN** ユーザーが `totp github` を実行し、`$TOTP_DIR/github` は存在するが読み取り権限がない
- **THEN** システムはエラーメッセージを表示し、TOTP コードは出力しない

### Requirement: oathtool 欠如時のエラー
システムは `totp <site>` の実行時に `oathtool` コマンドの存在を確認しなければならない（SHALL）。`oathtool` が見つからない場合、fish 標準の `command not found` エラーの代わりに、`oathtool` のインストールを促す独自のエラーメッセージを表示し、TOTP コードは出力してはならない（SHALL NOT）。このチェックはプラグイン読み込み時ではなく、コマンド実行時に行わなければならない（SHALL）。

#### Scenario: oathtool が未インストールの環境で totp を実行する
- **WHEN** `oathtool` コマンドが `PATH` 上に存在しない状態で `totp github` を実行する
- **THEN** システムは `oathtool` のインストールを促すメッセージを表示し、TOTP コードは出力しない

#### Scenario: oathtool 未インストールでもプラグイン読み込みは失敗しない
- **WHEN** `oathtool` コマンドが `PATH` 上に存在しない状態で fish シェルを起動する
- **THEN** プラグインの読み込みはエラーにならず、`totp` コマンドと補完は正常に登録される
