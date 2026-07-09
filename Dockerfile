FROM ubuntu:24.04

# システムパッケージのアップデートと依存ツールのインストール
RUN apt update && apt-get install -y fish jq python3 oathtool curl

# デフォルトシェルを fish に変更
SHELL ["fish", "-c"]

# fisher (プラグインマネージャー) のインストール
RUN curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher

# 作業ディレクトリの設定
WORKDIR /src/fish-totp

# リポジトリのソースコードをコンテナにコピー
COPY functions/ functions/
COPY completions/ completions/
COPY conf.d/ conf.d/
COPY README.md README.md
COPY test/ test/

# fish-totp プラグインをローカルからインストール
RUN fisher install .

# コンテナ起動時に fish を実行
CMD ["fish"]

