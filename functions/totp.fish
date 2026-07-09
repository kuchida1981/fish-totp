function totp
    # 1. サブコマンドディスパッチ (add, remove, ls, show)
    set -l cmd $argv[1]
    switch "$cmd"
        case add remove ls show
            totp_$cmd $argv[2..]
            return $status
    end

    # 2. command -q oathtool で存在確認
    if not command -q oathtool
        echo "oathtool is required. Please install it to use this plugin." >&2
        echo "Reference: https://www.gnu.org/software/oath-toolkit/" >&2
        return 1
    end

    # 3. jq の存在確認
    _totp_require_jq; or return 1

    # 4. $argv[1] を <site> として使う
    set -l site $argv[1]

    # 5. $TOTP_DIR/<site> の存在確認
    if not test -f "$TOTP_DIR/$site"
        echo "unknown site: $site" >&2
        return 1
    end

    # 6. ファイルの読み取り可能性確認
    if not test -r "$TOTP_DIR/$site"
        echo "error: cannot read secret file for $site" >&2
        return 1
    end

    # 7. jq で JSON から secret を取得
    set -l secret (jq -r .secret "$TOTP_DIR/$site")
    if test $status -ne 0
        return 1
    end

    # 8. oathtool を実行し、6桁のTOTPコードを標準出力に出力
    oathtool --totp --base32 "$secret"
end
