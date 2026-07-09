function totp
    # 1. command -q oathtool で存在確認
    if not command -q oathtool
        echo "oathtool is required. Please install it to use this plugin." >&2
        echo "Reference: https://www.gnu.org/software/oath-toolkit/" >&2
        return 1
    end

    # 2. $argv[1] を <site> として使う
    set -l site $argv[1]

    # 3. $TOTP_DIR/<site> の存在確認
    if not test -f "$TOTP_DIR/$site"
        echo "unknown site: $site" >&2
        return 1
    end

    # 4. ファイルの読み取り可能性確認
    if not test -r "$TOTP_DIR/$site"
        echo "error: cannot read secret file for $site" >&2
        return 1
    end

    # 5. oathtool を実行し、6桁のTOTPコードを標準出力に出力
    oathtool --totp --base32 "$(cat "$TOTP_DIR/$site")"
end
