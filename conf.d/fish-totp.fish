if not set -q TOTP_DIR
    set -g TOTP_DIR ~/.config/totp
end

if not set -q TOTP_VERSION
    set -g TOTP_VERSION "0.1.0"
end
