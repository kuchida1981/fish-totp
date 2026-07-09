## Context

fish-totp は現在 `functions/totp.fish` 1関数のみで構成され、`$TOTP_DIR/<site>` に置かれたプレーンテキストの Base32 シークレットを `cat` して `oathtool` に渡すだけの実装になっている。今回、サイトの登録・削除・一覧・詳細表示（`add`/`remove`/`ls`/`show`）を追加するにあたり、`otpauth://` URI からの登録に対応させたい。URI にはシークレット以外に issuer・account・algorithm・digits・period のメタデータが含まれるため、これを保持できるようストレージ形式を JSON に変更する。

本プロジェクトはまだ実運用前（`$TOTP_DIR` に実ファイルを置いて使っているユーザーがいない）であるため、既存フォーマットとの後方互換シムは設けず、破壊的にストレージ形式を変更してよい前提で設計する。

## Goals / Non-Goals

**Goals:**
- `totp add`（URI渡し / secret単体渡しの2パターン）、`totp remove`、`totp ls`、`totp show` を実装する
- シークレットを issuer/account/algorithm/digits/period 付きの JSON として保存する
- `totp <site>` のコード生成を、新しい JSON ストレージ形式から secret を取り出す形に追随させる

**Non-Goals:**
- 既存プレーンテキストファイルからの自動移行・後方互換読み込み（実運用前のため不要）
- `algorithm`/`digits`/`period` を実際の TOTP 生成（`oathtool` 呼び出し）に反映すること（保存のみ。生成は引き続き SHA1/6桁/30秒固定）
- 対話的プロンプトによる入力補完（サイト名・メタデータが不足している場合は常にエラーとし、`read` 等での対話は行わない）
- クリップボードコピー、QRコード、fzf連携、`pass`/`gopass` 連携など README の他の Future Ideas 項目

## Decisions

### 1. ストレージ形式は JSON、ファイル名規約は維持
`$TOTP_DIR/<site>` というファイル名規約（1ファイル = 1サイト）はそのまま維持し、ファイルの中身だけを以下の JSON に変更する。

```json
{
  "secret": "JBSWY3DPEHPK3PXP",
  "issuer": "GitHub",
  "account": "byebyeearthjpn@gmail.com",
  "algorithm": "SHA1",
  "digits": 6,
  "period": 30
}
```

`algorithm`/`digits`/`period` は otpauth:// URI 側で省略された場合も、otpauth の仕様上のデフォルト値（`SHA1`/`6`/`30`）を補完して保存する（`null` のまま保存しない）。これにより `show` の表示が常に一貫し、将来 algorithm 対応の generation ロジックを追加する際もデータ側の変更が不要になる。

代替案として「拡張子で新旧フォーマットを区別する」「ファイル名はそのまま、値だけ格納する軽量フォーマットにする」も検討したが、ファイル名規約を変えると `completions/totp.fish` の補完ロジック（ディレクトリ内ファイル名一覧）に手を入れる必要が生じるため、影響範囲を最小化する目的でファイル名は不変とした。

### 2. `totp <site>` は `jq -r .secret` で secret を取り出す
既存の `oathtool --totp --base32 "$(cat "$TOTP_DIR/$site")"` を `oathtool --totp --base32 "$(jq -r .secret "$TOTP_DIR/$site")"` に変更する。`jq` の存在確認は既存の `oathtool` チェックと同じパターン（`command -q jq` → 無ければインストールを促すメッセージを表示して `return 1`）で行う。

### 3. otpauth:// URI のパースは python3 の `urllib.parse` に委譲する
otpauth URI の `label` 部分（`issuer:account` 形式）はパーセントエンコードされており（例: `%3A` → `:`, `%40` → `@`）、マルチバイト文字（日本語の issuer 名等）を含む可能性もある。fish の `string` コマンド群だけで正確な URL デコードを実装するのは煩雑かつバグを生みやすいため、`python3 -c` でインラインスクリプトを実行し `urllib.parse.urlparse`/`parse_qs`/`unquote` で分解した結果を JSON として標準出力させる。

```
otpauth://totp/GitHub:byebyeearthjpn%40gmail.com?secret=XXX&issuer=GitHub
        │
        ▼ python3 -c "...urllib.parse..." → JSON化 {secret, issuer, account, algorithm, digits, period}
        │
        ▼ jq で --name/--issuer 等の CLI オプション引数を上書きマージ（CLI引数が常に優先）
        │
        ▼ $TOTP_DIR/<site> に書き込み（既存ファイルがあればエラー）
```

label に `issuer:account` の形式で issuer が含まれ、かつ `issuer` クエリパラメータも別途存在する場合は、otpauth の仕様上両者が一致することが期待されるが、本実装では **クエリパラメータの `issuer` を正とする**（クエリパラメータが省略された場合のみ label 側の issuer を fallback として使う）。

`python3` の存在確認も `jq`/`oathtool` と同じパターンで行う。

### 4. サイト名（ファイル名）の決定ロジック
- secret 単体渡し: `--name` 必須。省略時はエラーで終了する（対話プロンプトでの補完は行わない）
- URI 渡し: `--name` 省略時は抽出した `issuer` をサイト名として自動採用する。`--name` が明示されていればそれを優先する
- 決定したサイト名に `/` を含む、または空文字列になる場合はエラーとし、`--name` での明示指定を促す（issuer 名がファイル名として不適切な文字を含むケースへの対処）
- 決定したサイト名のファイルが `$TOTP_DIR` に既に存在する場合は、上書きせずエラーにする（`add` に `--force` 等の上書きオプションは設けない。上書きしたい場合は `remove` してから `add` する）

### 5. CLI オプション引数は常にパース結果より優先
secret単体・URI渡しのどちらの経路でも、最終的に `--name`/`--issuer`/`--account`/`--algorithm`/`--digits`/`--period` という共通のオプション引数セットで上書きできるようにする。実装上は「まずベースとなる JSON（secret単体なら空メタデータ、URIならパース結果）を組み立て、その後 `argparse` で受け取った非空のオプション値を jq でマージする」という単一の2段階パイプラインに統一し、2経路で分岐ロジックを重複させない。

### 6. サブコマンドディスパッチ
`functions/totp.fish` を、第一引数が `add`/`remove`/`ls`/`show` のいずれかであればサブコマンド関数（`functions/totp_add.fish` 等）に委譲し、それ以外は既存通りサイト名としてコード生成する、という分岐に変更する。各サブコマンドの引数パースには fish 標準の `argparse` ビルトインを使う。

### 7. `remove` は確認プロンプトなしで即削除
対話プロンプトを設けない全体方針と一貫させる。誤操作対策はシェル履歴・バックアップ側の責務とし、アプリケーション側では行わない。

### 8. `show` は secret を含む全メタデータを表示する
`show` は登録内容の確認・デバッグ・バックアップ用途を想定し、issuer/account/algorithm/digits/period に加えて secret 自体も表示する。TOTP コードそのものは `totp <site>` で別途取得できるため、`show` は「保存されている生データの確認」という役割に徹する。

## Risks / Trade-offs

- **[Risk]** `python3` という比較的重い新規依存が増える → **[Mitigation]** `oathtool`/`jq` と同じ存在チェックパターンを適用し、未インストール時は明確なエラーメッセージでインストールを促す。README の Requirements に明記する
- **[Risk]** 既存フォーマット（プレーンテキスト）のファイルを持つユーザーがいた場合、`totp <site>` が `jq` のパースエラーで壊れる → **[Mitigation]** 現時点で実運用ユーザーがいないことを確認済み。破壊的変更として proposal に明記し、READMEでも移行不要である旨は触れない（対象ユーザーがいないため）
- **[Risk]** issuer名の自動サイト名採用により、同一issuerの複数アカウントを誤って上書きしようとしてエラーになり、ユーザーが原因を理解しにくい可能性 → **[Mitigation]** エラーメッセージで「既に存在するため `--name` で別名を指定してください」と明示する
- **[Trade-off]** `algorithm`/`digits`/`period` を保存はするが生成に反映しないため、非SHA1/非6桁のサービスを登録しても `totp <site>` は誤ったコードを生成する → 現時点では Non-Goal と明記し、将来の別changeで対応する

## Migration Plan

実運用ユーザーがいないため、データ移行は不要。実装後、README の Secret Storage / Command Behavior / Requirements / Future Ideas セクションを更新し、`openspec/specs/totp-generation/spec.md` の該当 Requirement を新フォーマットに合わせて更新する。ロールバックは通常の git revert で対応する。

## Open Questions

- `algorithm`/`digits`/`period` を実際の生成に反映する対応は別changeとして切り出す想定だが、優先度は未定
- `totp export`（JSON → otpauth:// URI への逆変換）は今回のスコープ外だが、JSON側にメタデータを保持しているため将来追加は容易
