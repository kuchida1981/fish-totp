## 1. テスト基盤

- [ ] 1.1 `test/helpers.fish` を作成し、`assert_eq` / `assert_status` / `assert_match` などのアサートヘルパーと、テストケースの登録・失敗カウント集計の仕組みを実装する
- [ ] 1.2 `test/run.fish` を作成し、`test/*.test.fish` を読み込んで全テストケースを順に実行し、1件でも失敗があれば非ゼロの終了コードで終了するようにする

## 2. インストール検証テスト

- [ ] 2.1 `test/install.test.fish` を作成し、`fisher install .` 実行後に `totp`/`totp_add`/`totp_ls`/`totp_remove`/`totp_show` の各関数がロードされていることを確認するテストケースを実装する

## 3. コマンド挙動テスト

- [ ] 3.1 `test/totp.test.fish` を作成し、`totp` コマンドの正常系（有効なsiteで6桁数字が出力される）・異常系（unknown site、`jq`/`oathtool` 欠如時のエラー）のテストケースを実装する
- [ ] 3.2 `test/totp_add.test.fish` を作成し、otpauth URI からの追加、secret単体渡し時の `--name` 必須チェック、既存site上書き防止、`--issuer`/`--algorithm`/`--digits`/`--period` によるオプション上書きのテストケースを実装する
- [ ] 3.3 `test/totp_ls.test.fish` を作成し、`TOTP_DIR` 配下のファイル一覧表示（空の場合を含む）のテストケースを実装する
- [ ] 3.4 `test/totp_remove.test.fish` を作成し、削除の正常系とパストラバーサル対策（`/` を含むsite名の拒否）のテストケースを実装する
- [ ] 3.5 `test/totp_show.test.fish` を作成し、詳細表示の正常系とパストラバーサル対策（`/` を含むsite名の拒否）のテストケースを実装する

## 4. CI

- [ ] 4.1 `.github/workflows/ci.yml` を作成し、`push`/`pull_request` トリガー、fish 公式PPA導入、`jq`/`oathtool`/`python3`/`fisher` のセットアップ、`fisher install .` 実行、`test/run.fish` 実行の各ステップを実装する

## 5. ローカル動作確認用 Dockerfile

- [ ] 5.1 `Dockerfile` に `fisher install .` 相当のステップ（リポジトリ内容のコピーとインストール）を追加し、`git add` で管理下に置く

## 6. ドキュメント更新

- [ ] 6.1 `README.md` にテストの実行方法（`fish test/run.fish`）と CI バッジを追記する
