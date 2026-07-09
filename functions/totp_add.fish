function totp_add
    # 1. jq の存在確認
    _totp_require_jq; or return 1

    # 2. オプション解析
    argparse n/name= i/issuer= a/account= algorithm= digits= period= -- $argv
    or return 1

    # 3. 位置引数の数を確認
    if test (count $argv) -ne 1
        echo "error: secret or otpauth:// URI is required" >&2
        return 1
    end

    set -l input $argv[1]
    set -l base_json ""

    # 4. 判定ロジックとパース
    if string match -q 'otpauth://*' -- "$input"
        # 4-1. python3 の存在確認
        if not command -q python3
            echo "python3 is required. Please install it to use this plugin." >&2
            return 1
        end

        set -l python_code 'import sys, json
from urllib.parse import urlparse, parse_qs, unquote
try:
    uri = sys.argv[1]
    parsed = urlparse(uri)
    path = parsed.path.lstrip("/")
    label = unquote(path)
    if ":" in label:
        label_issuer, label_account = label.split(":", 1)
    else:
        label_issuer = None
        label_account = label
    qs = parse_qs(parsed.query)
    secret = qs.get("secret", [None])[0]
    issuer = qs.get("issuer", [None])[0]
    if not issuer:
        issuer = label_issuer
    account = label_account
    algorithm = qs.get("algorithm", ["SHA1"])[0]
    digits_str = qs.get("digits", [None])[0]
    try:
        digits = int(digits_str) if digits_str else 6
    except ValueError:
        digits = 6
    period_str = qs.get("period", [None])[0]
    try:
        period = int(period_str) if period_str else 30
    except ValueError:
        period = 30
    print(json.dumps({"secret": secret, "issuer": issuer, "account": account, "algorithm": algorithm, "digits": digits, "period": period}))
except Exception as e:
    sys.stderr.write(str(e) + "\n")
    sys.exit(1)'

        set base_json (python3 -c $python_code "$input")
        if test $status -ne 0
            echo "error: failed to parse otpauth:// URI" >&2
            return 1
        end
    else
        # secret 単体渡しの場合
        if not set -q _flag_name
            echo "error: --name is required when adding a secret without an otpauth:// URI" >&2
            return 1
        end

        set base_json (jq -n --arg secret "$input" '{secret: $secret, issuer: null, account: null, algorithm: null, digits: null, period: null}')
        if test $status -ne 0
            echo "error: failed to construct base JSON for secret" >&2
            return 1
        end
    end

    # 5. サイト名の決定
    set -l name ""
    if set -q _flag_name
        set name "$_flag_name"
    else
        # otpauth:// URI 渡しで --name が省略された場合
        set -l parsed_issuer (echo "$base_json" | jq -r .issuer)
        if test "$parsed_issuer" != "null"; and test -n "$parsed_issuer"
            set name "$parsed_issuer"
        end
    end

    # 6. サイト名の妥当性検証
    if test -z "$name"; or string match -q '*/*' -- "$name"
        echo "error: invalid site name '$name'. Please specify a valid site name with --name." >&2
        return 1
    end

    # 7. 上書き防止
    if test -f "$TOTP_DIR/$name"
        echo "error: site '$name' already exists" >&2
        return 1
    end

    # 8. オプション引数による上書き（共通）
    set -l jq_args
    set -l jq_filter "."

    if set -q _flag_issuer
        set -a jq_args --arg issuer "$_flag_issuer"
        set jq_filter "$jq_filter | .issuer = \$issuer"
    end
    if set -q _flag_account
        set -a jq_args --arg account "$_flag_account"
        set jq_filter "$jq_filter | .account = \$account"
    end
    if set -q _flag_algorithm
        set -a jq_args --arg algorithm "$_flag_algorithm"
        set jq_filter "$jq_filter | .algorithm = \$algorithm"
    end
    if set -q _flag_digits
        if string match -q -r '^[0-9]+$' -- "$_flag_digits"
            set -a jq_args --argjson digits "$_flag_digits"
            set jq_filter "$jq_filter | .digits = \$digits"
        else
            echo "error: --digits must be a number" >&2
            return 1
        end
    end
    if set -q _flag_period
        if string match -q -r '^[0-9]+$' -- "$_flag_period"
            set -a jq_args --argjson period "$_flag_period"
            set jq_filter "$jq_filter | .period = \$period"
        else
            echo "error: --period must be a number" >&2
            return 1
        end
    end

    set -l final_json (echo "$base_json" | jq $jq_args "$jq_filter")
    if test $status -ne 0
        echo "error: failed to update JSON with options" >&2
        return 1
    end

    # 9. ディレクトリ作成および書き込み
    mkdir -p "$TOTP_DIR"
    if test $status -ne 0
        echo "error: failed to create directory $TOTP_DIR" >&2
        return 1
    end

    printf "%s\n" "$final_json" > "$TOTP_DIR/$name"
    if test $status -ne 0
        echo "error: failed to write to $TOTP_DIR/$name" >&2
        return 1
    end
end
