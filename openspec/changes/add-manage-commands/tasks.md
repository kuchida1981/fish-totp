## 1. totp-generation: JSONストレージへの追随

- [ ] 1.1 `functions/totp.fish` の secret 取得を `cat` から `jq -r .secret` 経由に変更する
- [ ] 1.2 `totp <site>` 実行時に `jq` の存在確認を追加し、未インストール時は `oathtool` と同様のパターンでインストールを促すメッセージを表示して `return 1` する
- [ ] 1.3 シークレットファイルの内容が妥当な JSON として解析できない場合のエラーハンドリングを追加する（エラーメッセージを表示し、TOTP コードは出力しない）

## 2. サブコマンドディスパッチの追加

- [ ] 2.1 `functions/totp.fish` に、第一引数が `add`/`remove`/`ls`/`show` の場合はそれぞれの関数に委譲し、それ以外は既存通りサイト名として扱う分岐ロジックを追加する

## 3. `totp add` の実装

- [ ] 3.1 `functions/totp_add.fish` を新規作成し、`argparse` で `--name`/`--issuer`/`--account`/`--algorithm`/`--digits`/`--period` を受け取れるようにする
- [ ] 3.2 引数が `otpauth://` で始まるか（URI渡し）、それ以外（secret単体渡し）かを判定するロジックを実装する
- [ ] 3.3 secret単体渡しの場合: `--name` が省略されていればエラーメッセージを表示して終了する処理を実装する
- [ ] 3.4 secret単体渡しの場合: `jq -n` でベースとなる JSON（secret のみ設定、issuer/account 等は未設定）を組み立てる処理を実装する
- [ ] 3.5 URI渡しの場合: `python3 -c` によるインラインスクリプトで `urllib.parse` を用いて `secret`/`issuer`/`account`/`algorithm`/`digits`/`period` を抽出し、`algorithm`/`digits`/`period` が省略されていれば `SHA1`/`6`/`30` を補完してJSONとして出力する処理を実装する
- [ ] 3.6 URI渡しの場合: `--name` が省略されていれば抽出した `issuer` をサイト名として自動採用する処理を実装する
- [ ] 3.7 `jq` を用いて、`argparse` で明示指定されたオプション引数の値をベースJSONより優先してマージする処理を実装する（secret単体・URI渡し共通のロジックにする）
- [ ] 3.8 決定したサイト名が空文字列、または `/` を含む場合にエラーメッセージを表示して終了する検証処理を実装する
- [ ] 3.9 決定したサイト名のファイルが `$TOTP_DIR` に既に存在する場合、上書きせずエラーメッセージを表示して終了する処理を実装する
- [ ] 3.10 `totp add` 実行時に `jq`（常時）・`python3`（URI渡し時のみ）の存在確認を追加し、未インストール時はインストールを促すメッセージを表示して終了する処理を実装する

## 4. `totp remove` の実装

- [ ] 4.1 `functions/totp_remove.fish` を新規作成する
- [ ] 4.2 指定サイトが `$TOTP_DIR` に存在しない場合、`unknown site: <site>` エラーメッセージを表示して終了する処理を実装する
- [ ] 4.3 指定サイトが存在する場合、確認プロンプトなしで即座に `$TOTP_DIR/<site>` を削除する処理を実装する

## 5. `totp ls` の実装

- [ ] 5.1 `functions/totp_ls.fish` を新規作成し、`$TOTP_DIR` 配下のファイル名（サイト名）一覧を標準出力に出力する処理を実装する

## 6. `totp show` の実装

- [ ] 6.1 `functions/totp_show.fish` を新規作成し、`jq` で指定サイトの JSON（`secret` を含む全フィールド）を整形して標準出力に表示する処理を実装する
- [ ] 6.2 指定サイトが `$TOTP_DIR` に存在しない場合、`unknown site: <site>` エラーメッセージを表示して終了する処理を実装する

## 7. 補完の更新

- [ ] 7.1 `completions/totp.fish` に `add`/`remove`/`ls`/`show` サブコマンドを補完候補として追加する（既存のサイト名補完は維持する）

## 8. ドキュメント更新

- [ ] 8.1 README の Requirements セクションに `jq`・`python3` を追加する
- [ ] 8.2 README の Secret Storage セクションを JSON 形式の説明に更新する
- [ ] 8.3 README の Command Behavior セクションを `jq` を用いた生成方法に更新する
- [ ] 8.4 README の Usage セクションに `totp add`/`totp remove`/`totp ls`/`totp show` の使用例を追加する
- [ ] 8.5 README の Future Ideas から実装済みとなった `ls`/`add`/`remove`/`show` の項目を削除する
