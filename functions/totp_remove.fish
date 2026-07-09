function totp_remove
    # 1. jq の存在確認
    if not command -q jq
        echo "jq is required. Please install it to use this plugin." >&2
        return 1
    end

    # 2. 引数のチェック
    if test (count $argv) -ne 1
        echo "error: site name is required" >&2
        return 1
    end

    set -l site $argv[1]

    # 3. 存在確認
    if not test -f "$TOTP_DIR/$site"
        echo "unknown site: $site" >&2
        return 1
    end

    # 4. 削除
    rm -f "$TOTP_DIR/$site"
end
