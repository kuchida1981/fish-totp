function test_totp_generates_6_digit_code_for_valid_site
    printf '{"secret":"JBSWY3DPEHPK3PXP"}\n' >"$TOTP_DIR/github"
    set -l output (totp github)
    set -l s $status
    assert_status 0 $s "totp github should exit with status 0"
    assert_match '^[0-9]{6}$' "$output" "totp github should output a 6-digit code"
end

function test_totp_reports_error_for_unknown_site
    set -l err_file (mktemp)
    totp nosuchsite >/dev/null 2>$err_file
    set -l s $status
    assert_failure $s "totp should fail for unknown site"
    assert_match 'unknown site' (cat $err_file) "should report unknown site in stderr"
    rm -f $err_file
end

function test_totp_fails_without_jq
    printf '{"secret":"JBSWY3DPEHPK3PXP"}\n' >"$TOTP_DIR/github"
    set -l err_file (mktemp)
    _test_without_command jq totp github >/dev/null 2>$err_file
    set -l s $status
    assert_failure $s "totp should fail when jq is missing"
    assert_match 'jq is required' (cat $err_file) "should report missing jq in stderr"
    rm -f $err_file
end

function test_totp_fails_without_oathtool
    printf '{"secret":"JBSWY3DPEHPK3PXP"}\n' >"$TOTP_DIR/github"
    set -l err_file (mktemp)
    _test_without_command oathtool totp github >/dev/null 2>$err_file
    set -l s $status
    assert_failure $s "totp should fail when oathtool is missing"
    assert_match 'oathtool is required' (cat $err_file) "should report missing oathtool in stderr"
    rm -f $err_file
end
