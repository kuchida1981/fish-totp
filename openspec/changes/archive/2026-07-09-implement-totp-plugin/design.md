## Context

`fish-totp` はまだ `idea.md` に記述されたアイデアのみで、コードは一切存在しない。fisher でインストールされる fish shell プラグインとして、`totp <site>` コマンドとその補完を提供する最小構成を実装する。`oathtool` の呼び出しをラップするだけで、TOTP アルゴリズム自体は実装しない。

## Goals / Non-Goals

**Goals:**
- fisher の標準レイアウト（`functions/`, `completions/`, `conf.d/`）に従い、`fisher install <owner>/fish-totp` でそのまま動作するようにする
- `TOTP_DIR` 配下のファイル一覧を単一の情報源として、コマンド実行と補完の両方に使う
- `oathtool` 欠如時・不正なサイト指定時に、原因が分かるエラーメッセージを出す

**Non-Goals:**
- TOTP アルゴリズムの実装、秘密鍵の暗号化、認証情報の同期、GUI（`idea.md` の Non-goals を継承）
- `idea.md` の Future Ideas（サブコマンド群、外部シークレットマネージャ連携、`fzf` 連携、残り有効時間表示）
- `TOTP_DIR` ディレクトリの自動作成（存在しない場合はエラーとし、作成はユーザーに委ねる）
- テストフレームワークの導入（本 change ではスコープ外。手動確認で十分な規模）

## Decisions

### 1. ファイルレイアウトは fisher 標準の3ディレクトリに分離する
`functions/totp.fish`、`completions/totp.fish`、`conf.d/fish-totp.fish` に分離する。fisher は `functions/*.fish` と `completions/*.fish` をそれぞれ fish のパスにシンボリックリンクし、`conf.d/*.fish` はシェル起動時に自動 source する。fisher コミュニティの一般的な構成に従うことで、他の fisher プラグインと同じメンタルモデルで扱える。

代替案: `functions/totp.fish` 内に `complete` コマンドも同居させる方式も fish では可能だが、fisher の「1関数=1ファイル」という素直な構成から外れるため採用しない。

### 2. 補完は `completions/totp.fish` 内で `$TOTP_DIR` を動的に `ls` する
```fish
complete -c totp -f -a '(ls $TOTP_DIR 2>/dev/null)'
```
のように、補完呼び出しごとにディレクトリを読む。サイトの追加がファイル配置だけで即座に補完へ反映されるという `idea.md` の要件に対して、キャッシュや別途登録の仕組みを持たないシンプルな方式が合致する。

代替案: `totp.fish` 側で引数解析ロジックを持ち、補完もそこに委ねる方式は、将来 `totp add`/`totp remove` 等のサブコマンドが増えた際には一元管理しやすいが、現時点ではオーバーエンジニアリングになるため見送る。

### 3. `TOTP_DIR` 環境変数を初期実装から導入する
`conf.d/fish-totp.fish` で以下のようにデフォルト値を設定する。

```fish
if not set -q TOTP_DIR
    set -g TOTP_DIR ~/.config/totp
end
```

（`set -q TOTP_DIR; or set -g TOTP_DIR ~/.config/totp` という `or` 形式も等価に見えるが、fish 3.7.1 では直前の失敗コマンドの影響で `set -g` 自体の exit status が 1 になり、プラグイン読み込みのたびに `$status` が汚れる問題があったため `if` 文形式を採用する。動作確認〈6.5〉で発見。）`idea.md` では Future Ideas 扱いだったが、`functions/` と `completions/` の両方が同じパスを参照する必要があるため、変数化しておかないと後から2箇所を書き換えるコストが発生する。ハードコードから変数への変更は本質的に無料ではないため、最初から変数化する。

### 4. `oathtool` の欠如チェックは実行時のみ、プラグイン読み込み時には行わない
`conf.d/fish-totp.fish` では `oathtool` の存在確認をしない。`functions/totp.fish` の実行冒頭で `command -q oathtool` をチェックし、無ければ fish 標準の `command not found: oathtool` の代わりに、インストール方法を示す独自メッセージを表示して終了する。

理由: プラグイン読み込み時（シェル起動時）に毎回外部コマンドの存在確認をするのはシェル起動を遅くする可能性があり、かつ `oathtool` を後からインストールする運用（`totp` を使うまで待つ）を妨げない。エラーメッセージの親切さは実行時のチェックで十分に提供できる。

### 5. サイト未存在・ファイル読み取り不可はいずれも `totp.fish` 内でチェックしてから `oathtool` を呼ぶ
`$TOTP_DIR/<site>` の存在確認 → 読み取り可能性の確認 → `oathtool` 呼び出しの順で行う。`idea.md` に明記された `unknown site: <site>` のメッセージ形式をそのまま採用する。

## Risks / Trade-offs

- [補完の `ls` 方式はディレクトリ内に大量のファイルがあると毎回のTAB補完が遅くなる可能性がある] → 想定される秘密鍵ファイル数は数十程度であり、実用上問題にならない。将来的に問題化した場合はキャッシュを検討する。
- [`TOTP_DIR` を早期に変数化することでテストコストが実装当初からわずかに増える（環境変数を意識した実装が必要）] → `conf.d/` で一箇所デフォルトを設定するだけなので実装コストは無視できる。
- [`oathtool` 欠如時のエラーメッセージがプラットフォームごとのインストール手順（Homebrew/apt等）を網羅できない] → 特定のパッケージマネージャに依存しない一般的な文言（"oathtool をインストールしてください" + 参考リンクや代表的なコマンド例)にとどめる。

## Open Questions

- テスト（fishtape 等）を導入するかどうかは本 change では未決定。導入する場合は別 change として提案する。
