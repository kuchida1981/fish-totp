function _totp_require_jq
    if not command -q jq
        echo "jq is required. Please install it to use this plugin." >&2
        return 1
    end
end
