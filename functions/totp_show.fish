function totp_show
    # 1. jq の存在確認
    _totp_require_jq; or return 1

    # 2. 引数チェック
    if test (count $argv) -ne 1
        echo "error: site name is required" >&2
        return 1
    end

    set -l site $argv[1]

    # パストラバーサル防止
    if string match -q '*/*' -- "$site"
        echo "unknown site: $site" >&2
        return 1
    end

    # 3. 存在確認
    if not test -f "$TOTP_DIR/$site"
        echo "unknown site: $site" >&2
        return 1
    end

    # 読み取り可能性確認
    if not test -r "$TOTP_DIR/$site"
        echo "error: cannot read secret file for $site" >&2
        return 1
    end

    # 4. JSON を整形して表示
    jq . "$TOTP_DIR/$site"
end
