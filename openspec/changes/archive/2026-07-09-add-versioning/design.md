## Context

fish-totp は fisher で配布される fish shell プラグインで、`add`/`remove`/`ls`/`show` の4サブコマンドを `functions/totp.fish` 内の `switch` でディスパッチする構成になっている（`case add remove ls show` → `totp_$cmd $argv[2..]`）。バージョンを識別する仕組みは存在せず、`git tag` も1件も打たれていない。

fisher は `fisher install owner/repo@<tag>` の形式でタグ指定インストール・アップデートをサポートするため、tag は既に fisher ユーザーにとって意味を持つ。今回はこの tag と、プラグイン内部で保持する `TOTP_VERSION` の値を常に一致させることが要件になる。

## Goals / Non-Goals

**Goals:**
- `totp version` で現在インストールされているプラグインのバージョンを確認できるようにする
- リリース作成（タグ作成）とバージョン文字列の反映を1トランザクションにまとめ、両者のズレを構造的に起こさないようにする
- 手動オペレーションを「バージョン番号を1つ入力する」だけに縮小する

**Non-Goals:**
- CHANGELOG の自動生成（release-please 等の Conventional Commits ベースの自動化）は今回のスコープ外。将来必要になった時点で別 change として検討する
- semver の自動算出（`feat`/`fix` からの自動 bump 判定）は行わない。バージョン番号は人間が明示的に指定する
- `--version` オプションのサポートは行わない（`version` サブコマンドのみ。既存の `add`/`remove`/`ls`/`show` との一貫性を優先）

## Decisions

### 1. `totp version` はサブコマンドとして実装する（オプションではない）
既存の `add`/`remove`/`ls`/`show` はすべてサブコマンドであり、`totp.fish` のディスパッチ機構（`switch "$cmd"` → `totp_$cmd`）にそのまま乗せられる。`--version` フラグ方式は `argparse` などの新しいフラグ解析ロジックの導入を必要とし、現状のシンプルな「第一引数 = サブコマンド or サイト名」という設計と整合しない。

### 2. バージョン情報源は `conf.d/fish-totp.fish` の静的グローバル変数
`TOTP_DIR` のデフォルト値設定と同じ場所（`conf.d/fish-totp.fish`、プラグインロード時に自動実行される）に `set -g TOTP_VERSION "0.1.0"` を追加する。

検討した代替案:
- **`VERSION` ファイル + 実行時読み込み**: `status dirname` 等でファイルパスを解決する必要があり、fisher の symlink 経由のインストールで期待通り動作するか不確実性が残る。却下。
- **`git describe --tags` を実行時に呼ぶ**: fisher でインストールされた環境では `.git` が存在しない、または期待したパスにない可能性が高く、信頼性が低い。却下。

### 3. タグ作成前にバージョン文字列を反映する（順序が肝）
GitHub Release（tag）は作成された瞬間の commit を指す固定参照である。もし「tag 作成 → CI が事後的に `TOTP_VERSION` を書き換える」という順序にすると、`fisher install owner/repo@0.2.0` で該当タグをインストールしたユーザーの `totp version` が古い値を表示してしまう（tag の指す commit にはまだ新しいバージョン文字列が反映されていないため）。

これを避けるため、リリース Action は以下の順序で実行する:
1. `TOTP_VERSION` を書き換えてコミット
2. そのコミットに対して tag を作成
3. tag から GitHub Release を作成

この順序により、任意の tag が指す commit は常にその tag と同じ値の `TOTP_VERSION` を持つことが保証される。

### 4. tag 名にプレフィックスを付けない（`0.1.0`、`v0.1.0` ではない）
`TOTP_VERSION` の値と tag 名を完全一致させることで、両者の対応関係を人間にもスクリプトにも自明にする。`v` プレフィックスを付けると `TOTP_VERSION` との文字列比較や参照時に毎回プレフィックスの有無を意識する必要が生じるため、付けない方針とする。README にこの規約を明示する。

### 5. リリース Action はワンショットの `workflow_dispatch`（release-please は導入しない）
Conventional Commits ベースの自動 bump（release-please 等）は CHANGELOG 自動生成という利点があるが、コミットメッセージ規約の厳密運用が前提になり、fish-totp のような小規模・単独メンテナのプロジェクトには現時点でオーバースペック。まずは `workflow_dispatch` で `version` を人間が明示的に入力する、最小限の自動化から始める。将来 CHANGELOG 自動化が必要になれば別 change として release-please 導入を検討する。

### 6. リリース Action 内でテストスイートを実行する
`test/run.fish`（既存 CI と同様の手順）をリリース前に実行し、失敗時は後続のバージョン反映・タグ作成・Release作成を中断する。壊れた状態のコミットに tag が付いてしまうことを防ぐ。

### 7. `main` ブランチ限定のブランチガード
`workflow_dispatch` は手動トリガーのため、誤って別ブランチから実行されるリスクがある。ジョブの先頭で `github.ref` が `refs/heads/main` であることを確認し、そうでなければ即座に失敗させる。

### 8. リリースノートは `gh release create --generate-notes` に任せる
手動記述は運用コストが高く、GitHub の自動生成（直近 tag からの PR/commit 一覧）で当面は十分と判断。

## Risks / Trade-offs

- **[Risk]** semver 以外の形式（`v0.2.0`、`0.2` など）が `workflow_dispatch` の入力に渡される → **Mitigation**: ワークフロー内で `X.Y.Z` 形式の正規表現バリデーションを行い、不一致なら即座に失敗させる。
- **[Risk]** リリース Action が `main` への push 権限を持つため、誤操作やワークフロー内のバグでコミットが混入するリスク → **Mitigation**: `permissions: contents: write` を該当ジョブのみに絞り、コミットメッセージを `chore: release X.Y.Z` に固定して意図を明確にする。
- **[Risk]** 既存タグと重複するバージョンを指定してしまう → **Mitigation**: tag push 時に git が重複を拒否するため、ワークフローはその時点で失敗する（追加のガードは設けず git のデフォルト挙動に委ねる）。
- **[Trade-off]** CHANGELOG が自動生成されないため、リリースノートの質は `--generate-notes` の粒度（PRタイトルの列挙）に依存する。将来必要になれば release-please 導入を再検討する。

## Migration Plan

- 既存ユーザーへの破壊的変更なし。`totp version` は新規追加のサブコマンドであり、既存の `add`/`remove`/`ls`/`show`・裸の `totp <site>` の挙動に影響しない。
- 初回リリースとして `0.1.0` を上記フローで作成し、tag `0.1.0` と `TOTP_VERSION="0.1.0"` の対応を最初から成立させる。
- ロールバックが必要な場合は、該当 tag と GitHub Release を削除し、バージョン反映コミットを revert する。

## Open Questions

なし（explore での議論で主要な設計判断は確定済み）
