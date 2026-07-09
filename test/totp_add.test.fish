function test_totp_add_uri_creates_secret_file_from_otpauth_uri
    # 1. otpauth:// URI を渡すと、issuer をサイト名としてファイルが作成され、JSON に secret/issuer/account が正しく格納される
    set -l uri "otpauth://totp/GitHub:user@example.com?secret=JBSWY3DPEHPK3PXP&issuer=GitHub"
    totp_add "$uri"
    set -l s $status
    assert_success $s "totp_add with otpauth URI should succeed"

    # ファイルの存在確認
    test -f "$TOTP_DIR/GitHub"
    assert_success $status "GitHub file should be created"

    # JSON の内容検証
    set -l secret (jq -r .secret "$TOTP_DIR/GitHub")
    assert_eq "JBSWY3DPEHPK3PXP" "$secret" "secret should be JBSWY3DPEHPK3PXP"

    set -l issuer (jq -r .issuer "$TOTP_DIR/GitHub")
    assert_eq "GitHub" "$issuer" "issuer should be GitHub"

    set -l account (jq -r .account "$TOTP_DIR/GitHub")
    assert_eq "user@example.com" "$account" "account should be user@example.com"
end

function test_totp_add_bare_secret_fails_without_name
    # 2. secret 単体を --name なしで渡すとエラー終了し、--name is required 相当のメッセージが出る
    set -l err_file (mktemp)
    totp_add "JBSWY3DPEHPK3PXP" >/dev/null 2>$err_file
    set -l s $status
    assert_failure $s "totp_add bare secret without --name should fail"
    
    set -l err_msg (cat $err_file)
    assert_match "error: --name is required" "$err_msg" "stderr should contain '--name is required'"
    
    rm -f $err_file
end

function test_totp_add_bare_secret_creates_file_with_name
    # 3. secret 単体を --name <name> 付きで渡すと、指定した名前でファイルが作成される
    totp_add --name "my-custom-name" "JBSWY3DPEHPK3PXP"
    set -l s $status
    assert_success $s "totp_add bare secret with --name should succeed"

    # ファイルの存在確認
    test -f "$TOTP_DIR/my-custom-name"
    assert_success $status "my-custom-name file should be created"

    # JSON の内容検証
    set -l secret (jq -r .secret "$TOTP_DIR/my-custom-name")
    assert_eq "JBSWY3DPEHPK3PXP" "$secret" "secret should be JBSWY3DPEHPK3PXP"

    set -l issuer (jq -r .issuer "$TOTP_DIR/my-custom-name")
    assert_eq "null" "$issuer" "issuer should be null"

    set -l account (jq -r .account "$TOTP_DIR/my-custom-name")
    assert_eq "null" "$account" "account should be null"
end

function test_totp_add_refuses_to_overwrite_existing_site
    # 4. 既に存在する site 名で追加しようとするとエラー終了し、既存ファイルの内容が変更されない
    # 既存の site ファイルを作成
    printf '{"secret":"ORIGINAL_SECRET","issuer":"GitHub","account":"test@example.com"}\n' >"$TOTP_DIR/GitHub"

    set -l err_file (mktemp)
    totp_add "otpauth://totp/GitHub:user@example.com?secret=NEW_SECRET&issuer=GitHub" >/dev/null 2>$err_file
    set -l s $status
    assert_failure $s "totp_add to existing site should fail"

    set -l err_msg (cat $err_file)
    assert_match "error: site 'GitHub' already exists" "$err_msg" "stderr should contain 'already exists'"
    rm -f $err_file

    # ファイルが変更されていないことを確認
    set -l secret (jq -r .secret "$TOTP_DIR/GitHub")
    assert_eq "ORIGINAL_SECRET" "$secret" "secret should not be modified"
end

function test_totp_add_overrides_defaults_with_options
    # 5. --issuer/--algorithm/--digits/--period オプションで otpauth URI や secret 単体渡し時のデフォルト値を上書きできる
    set -l uri "otpauth://totp/GitHub:user@example.com?secret=JBSWY3DPEHPK3PXP&issuer=GitHub"
    totp_add --issuer "CustomIssuer" --account "custom@example.com" --algorithm "SHA256" --digits 8 --period 60 "$uri"
    set -l s $status
    assert_success $s "totp_add with override options should succeed"

    # ファイル名は元の issuer である GitHub になる
    test -f "$TOTP_DIR/GitHub"
    assert_success $status "GitHub file should be created"

    # JSON の内容検証
    set -l secret (jq -r .secret "$TOTP_DIR/GitHub")
    assert_eq "JBSWY3DPEHPK3PXP" "$secret" "secret should be JBSWY3DPEHPK3PXP"

    # issuer は --issuer で指定した CustomIssuer に上書きされている
    set -l issuer (jq -r .issuer "$TOTP_DIR/GitHub")
    assert_eq "CustomIssuer" "$issuer" "issuer should be CustomIssuer"

    set -l account (jq -r .account "$TOTP_DIR/GitHub")
    assert_eq "custom@example.com" "$account" "account should be custom@example.com"

    set -l algorithm (jq -r .algorithm "$TOTP_DIR/GitHub")
    assert_eq "SHA256" "$algorithm" "algorithm should be SHA256"

    set -l digits (jq -r .digits "$TOTP_DIR/GitHub")
    assert_eq "8" "$digits" "digits should be 8"

    set -l period (jq -r .period "$TOTP_DIR/GitHub")
    assert_eq "60" "$period" "period should be 60"
end

function test_totp_add_rejects_invalid_site_names
    # 6. サイト名にスラッシュを含む、または予約サブコマンド名（add/remove/ls/show）と衝突する場合はエラー終了する
    
    # スラッシュを含む場合
    set -l err_file (mktemp)
    totp_add --name "foo/bar" "JBSWY3DPEHPK3PXP" >/dev/null 2>$err_file
    set -l s $status
    assert_failure $s "totp_add with name containing slash should fail"
    assert_match "error: invalid site name" (cat $err_file) "stderr should report invalid site name"
    rm -f $err_file
    
    # 予約語 add
    set -l err_file (mktemp)
    totp_add --name "add" "JBSWY3DPEHPK3PXP" >/dev/null 2>$err_file
    set -l s $status
    assert_failure $s "totp_add with reserved name 'add' should fail"
    assert_match "error: invalid site name" (cat $err_file) "stderr should report invalid site name"
    rm -f $err_file

    # 予約語 remove
    set -l err_file (mktemp)
    totp_add --name "remove" "JBSWY3DPEHPK3PXP" >/dev/null 2>$err_file
    set -l s $status
    assert_failure $s "totp_add with reserved name 'remove' should fail"
    assert_match "error: invalid site name" (cat $err_file) "stderr should report invalid site name"
    rm -f $err_file

    # 予約語 ls
    set -l err_file (mktemp)
    totp_add --name "ls" "JBSWY3DPEHPK3PXP" >/dev/null 2>$err_file
    set -l s $status
    assert_failure $s "totp_add with reserved name 'ls' should fail"
    assert_match "error: invalid site name" (cat $err_file) "stderr should report invalid site name"
    rm -f $err_file

    # 予約語 show
    set -l err_file (mktemp)
    totp_add --name "show" "JBSWY3DPEHPK3PXP" >/dev/null 2>$err_file
    set -l s $status
    assert_failure $s "totp_add with reserved name 'show' should fail"
    assert_match "error: invalid site name" (cat $err_file) "stderr should report invalid site name"
    rm -f $err_file
end

function test_totp_add_fails_when_python3_is_missing
    # 7. python3 が PATH 上にない場合、otpauth URI 渡しはエラー終了する（secret単体渡しはpython3を使わないので影響しないことも確認するとよい）
    set -l uri "otpauth://totp/GitHub:user@example.com?secret=JBSWY3DPEHPK3PXP&issuer=GitHub"
    set -l err_file (mktemp)
    
    _test_without_command python3 totp_add "$uri" >/dev/null 2>$err_file
    set -l s $status
    assert_failure $s "totp_add with otpauth URI should fail without python3"
    assert_match "python3 is required" (cat $err_file) "stderr should report missing python3"
    rm -f $err_file

    # secret単体渡しはpython3を使わないので影響しない
    _test_without_command python3 totp_add --name "python-less-site" "JBSWY3DPEHPK3PXP"
    set -l s2 $status
    assert_success $s2 "totp_add with bare secret should succeed even without python3"
    
    test -f "$TOTP_DIR/python-less-site"
    assert_success $status "python-less-site file should be created"
end
