## Context

fish-totp は fisher プラグインとして配布される小規模リポジトリ（`functions/`, `completions/`, `conf.d/`）。現在テストが一切なく、`totp` サブコマンド群のパストラバーサル対策や権限チェックなどのリグレッションを検知できない。git remote は `kuchida1981/fish-totp`（GitHub）が設定済み。ローカル環境は fish 3.7.1。CI 実行環境は GitHub Actions の `ubuntu-latest` を想定。

依存コマンド: `oathtool`（必須）、`jq`（必須）、`python3`（otpauth URI パース時のみ必須）。

## Goals / Non-Goals

**Goals:**
- `fisher install .` によるインストール成功を自動検証する
- `totp`/`totp add`/`totp ls`/`totp remove`/`totp show` の正常系・異常系を自動検証する
- GitHub Actions で push/PR ごとに上記を自動実行する
- 外部テストフレームワークへの依存を増やさない

**Non-Goals:**
- TOTP コード生成の暗号学的な正しさの厳密検証（6桁数字であることのパターンマッチのみ行う）
- 複数 OS・複数 fish バージョンでのマトリクステスト（当面 ubuntu-latest + fish 公式 PPA 最新版のみ）
- パフォーマンステスト

## Decisions

**1. テストフレームワークは自前の fish スクリプトによる簡易アサート**
外部依存（fishtape 等）を増やさず、`test/helpers.fish` に `assert_eq`／`assert_status`／`assert_match` 相当のヘルパー関数を定義する。各テストファイル（`test/*.test.fish`）はテストケースを関数として定義し、`test/run.fish` が列挙・実行して合否をカウント、1件でも失敗があれば非ゼロ終了する。
- 代替案: fishtape 導入 → TAP 形式で見やすくなるが、テストのためだけの fisher 依存が増える。リポジトリ規模に見合わないため不採用。

**2. `TOTP_DIR` はテストケースごとに隔離**
各テスト実行前に `mktemp -d` で一時ディレクトリを作成し `TOTP_DIR` をローカルに上書き（`set -lx TOTP_DIR (mktemp -d)`）。テスト間の状態汚染を防ぐ。

**3. 依存コマンド欠如（`jq`/`oathtool`/`python3` なし）は PATH 操作でシミュレート**
テスト対象コマンドの実体パスを `command -s <cmd>` で確認した上で、それらのバイナリを含まない最小限のディレクトリ構成の PATH（`set -lx PATH /usr/bin /bin` 等、実行に必要な最低限のコマンドのみ残す）に一時的に切り替えてテストを実行する。
- 代替案: バイナリを一時的に `chmod -x` する → CI 環境で共有ランナーの `/usr/bin/jq` 等を書き換えるのは副作用が大きく不採用。PATH操作の方が安全でテスト後の復元も容易。

**4. TOTP コード検証はパターンマッチのみ**
`totp <site>` の出力を `string match -rq '^[0-9]{6}$'` で検証する。oathtool を直接実行して値を突き合わせる方式は、実行タイミングのずれ（30秒境界をまたぐ）でフレーキーになるリスクがあるため採用しない。

**5. `fisher install .` でインストールテストを行う**
CI 上ではチェックアウト済みのワーキングディレクトリをそのまま `fisher install .` に渡す。GitHub 経由（`fisher install kuchida1981/fish-totp`）ではなくローカルパスを使うことで、push 前のブランチの内容を確実にテストできる。インストール後 `functions -q totp; and functions -q totp_add; and functions -q totp_ls; and functions -q totp_remove; and functions -q totp_show` で関数のロードを確認する。

**6. fish バージョンは CI で公式 PPA から取得**
`ppa:fish-shell/release-3` を追加した上で `apt-get install fish` する。Ubuntu 標準リポジトリのバージョンはやや古いため、手元環境（3.7.1系）との乖離を避ける。

**7. CI ワークフローは単一ジョブ・複数ステップ構成**
`.github/workflows/ci.yml` に `push`/`pull_request` トリガーで以下のステップを定義する:
1. checkout
2. fish 公式 PPA 追加 → `fish`/`jq`/`oathtool`/`python3` を apt install
3. fisher 導入（`curl … | source && fisher install jorgebucaran/fisher`）
4. `fisher install .`（インストールテスト）+ 関数ロード確認
5. `fish test/run.fish`（コマンド挙動テスト）
ジョブを分割しない理由: リポジトリが小規模で実行時間も短く、ステップ単位で GitHub Actions UI 上の合否は十分判別できるため。

**8. `Dockerfile` を git 管理化し、`fisher install .` ステップを追加**
現状 `Dockerfile` は fisher 自体のインストールで止まっており、このプラグインを実際にインストールする行がない。プラグインのソースをコンテナにコピー（または bind mount）し `fisher install .` を実行するステップを追加した上で git 管理下に置く。CI では使わず、開発者がローカルでクリーンな環境の動作確認をするための用途に限定する。

## Risks / Trade-offs

- [自前アサートヘルパーは機能が薄い] → リポジトリ規模・テストケース数が少ないため許容範囲。将来テストが増えて辛くなったら fishtape 移行を再検討する。
- [PATH 操作によるコマンド欠如シミュレートは環境依存] → `command -s` で実体パスを動的検出してから除外する設計にし、CI/ローカルどちらでも動作するようにする。
- [`fisher install .` はローカルパス経由であり、README記載の `fisher install <owner>/<repo>` とは経路が異なる] → 配布物の構造（`functions/`/`completions/`/`conf.d/`）は経路によらず同一のため、実質的な検証価値は変わらない。将来的にタグ経由のインストールテストを追加する余地は Open Questions に残す。
- [公式PPAはUbuntu前提] → 現状 macOS/Windows でのCIは Non-Goal としているため許容。

## Migration Plan

新規ファイルの追加のみで既存の `functions/`/`completions/`/`conf.d/` には変更を加えない。ロールバックは追加したファイル（`test/`, `.github/workflows/ci.yml`, `Dockerfile`）を削除するだけで完了する。

## Open Questions

- 将来的に macOS ランナーや複数 fish バージョンでのマトリクス CI を追加するか
- リリースタグ経由（`fisher install kuchida1981/fish-totp@<tag>`）のインストールテストを別途追加するか
