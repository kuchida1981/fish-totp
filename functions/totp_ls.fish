function totp_ls
    # 1. jq の存在確認
    if not command -q jq
        echo "jq is required. Please install it to use this plugin." >&2
        return 1
    end

    # 2. $TOTP_DIR 内のファイル（サイト名）一覧を表示
    if test -d "$TOTP_DIR"
        for file in (command ls -1 "$TOTP_DIR" 2>/dev/null)
            if test -f "$TOTP_DIR/$file"
                echo "$file"
            end
        end
    end
end
