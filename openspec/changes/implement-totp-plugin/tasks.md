## 1. リポジトリ構成のセットアップ

- [ ] 1.1 `functions/`, `completions/`, `conf.d/` ディレクトリを作成する

## 2. TOTP_DIR のデフォルト設定

- [ ] 2.1 `conf.d/fish-totp.fish` を作成し、`TOTP_DIR` が未設定の場合のみ `~/.config/totp` を設定する

## 3. totp コマンド本体

- [ ] 3.1 `functions/totp.fish` に `totp` 関数を作成する
- [ ] 3.2 `command -q oathtool` で `oathtool` の存在を確認し、無ければインストールを促すメッセージを表示して終了する処理を実装する
- [ ] 3.3 `$TOTP_DIR/<site>` の存在確認を実装し、無ければ `unknown site: <site>` を表示して終了する処理を実装する
- [ ] 3.4 シークレットファイルが読み取れない場合にエラーメッセージを表示して終了する処理を実装する
- [ ] 3.5 `oathtool --totp --base32 "$(cat $TOTP_DIR/<site>)"` を実行し、TOTP コードを標準出力に出力する処理を実装する

## 4. 補完

- [ ] 4.1 `completions/totp.fish` を作成し、`$TOTP_DIR` 配下のファイル名一覧を動的補完候補として登録する

## 5. ドキュメント整備

- [ ] 5.1 `README.md` の Installation セクションを `fisher install <owner>/fish-totp` に更新する

## 6. 動作確認

- [ ] 6.1 `$TOTP_DIR` にテスト用シークレットファイルを配置し、`totp <site>` が正しい6桁コードを出力することを確認する
- [ ] 6.2 `totp <TAB>` でファイル名一覧が補完候補として表示されることを確認する
- [ ] 6.3 存在しないサイトを指定した場合に `unknown site: <site>` が表示されることを確認する
- [ ] 6.4 `oathtool` が存在しない環境で `totp <site>` を実行し、インストールを促すメッセージが表示されることを確認する
- [ ] 6.5 fisher でのプラグイン読み込み自体は `oathtool` の有無に関わらず失敗しないことを確認する
