## ADDED Requirements

### Requirement: TOTP_VERSION のデフォルト設定
プラグインは読み込み時に、`conf.d/fish-totp.fish` 内でグローバル変数 `TOTP_VERSION` を設定しなければならない（SHALL）。この値はリリースごとに更新される静的なバージョン文字列であり、semver 形式（`X.Y.Z`）で保持されなければならない（SHALL）。

#### Scenario: プラグインロード時に TOTP_VERSION が設定される
- **WHEN** fish shell がプラグインを読み込む
- **THEN** `TOTP_VERSION` にリリース済みのバージョン文字列（例: `0.1.0`）が設定されている

### Requirement: `totp version` サブコマンド
`totp version` を実行すると、システムは `TOTP_VERSION` の値を用いて `<プラグイン名> <バージョン>` 形式（例: `fish-totp 0.1.0`）の文字列を標準出力に出力しなければならない（SHALL）。このサブコマンドは既存の `add`/`remove`/`ls`/`show` と同じディスパッチ機構で処理されなければならない（SHALL）。

#### Scenario: バージョンを表示する
- **WHEN** ユーザーが `totp version` を実行する
- **THEN** システムは標準出力に `fish-totp <TOTP_VERSION の値>` を出力する

### Requirement: `version` の補完対応
`totp` の補完候補は、第一引数の位置で `version` を含まなければならない（SHALL）。

#### Scenario: `totp <TAB>` で version が候補に出る
- **WHEN** ユーザーが `totp ` の後で `<TAB>` 補完を行う
- **THEN** 補完候補に `add`・`remove`・`ls`・`show` に加えて `version` が含まれる
