function test_totp_show_prints_formatted_json_for_existing_site
    # 既存の site ファイルを作成
    printf '{"secret":"JBSWY3DPEHPK3PXP","issuer":"GitHub","account":"test@example.com"}\n' >"$TOTP_DIR/github"
    test -f "$TOTP_DIR/github"
    set -l exists $status
    assert_status 0 $exists "github file should exist initially"

    # totp_show を実行し出力をキャプチャ
    set -l output (totp_show github)
    set -l s $status
    assert_success $s "totp_show github should exit successfully"

    # 出力に secret が含まれていることを確認
    assert_match '"secret": "JBSWY3DPEHPK3PXP"' "$output" "output should contain the formatted secret"
    assert_match '"issuer": "GitHub"' "$output" "output should contain the formatted issuer"
end

function test_totp_show_rejects_path_traversal
    # 一時的な外部ファイルを作成
    set -l safe_file (mktemp)
    printf '{"secret":"EXTERNAL_SECRET"}\n' >"$safe_file"
    test -f "$safe_file"
    set -l exists $status
    assert_status 0 $exists "external safe file should exist initially"

    # / を含む site 名でエラー終了し、メッセージに 'unknown site' を含むことを確認
    set -l err_file (mktemp)
    totp_show "foo/bar" >/dev/null 2>$err_file
    set -l s $status
    assert_failure $s "totp_show with slash should fail"
    assert_match 'unknown site' (cat $err_file) "stderr should contain 'unknown site' for foo/bar"
    rm -f $err_file

    # 親ディレクトリや絶対パスのトラバーサルでのエラー確認
    set -l err_file2 (mktemp)
    set -l output (totp_show "$safe_file" 2>$err_file2)
    set -l s2 $status
    assert_failure $s2 "totp_show with absolute path should fail"
    assert_match 'unknown site' (cat $err_file2) "stderr should contain 'unknown site' for absolute path"

    # 外部ファイルの秘密情報が標準出力に含まれていないか確認
    assert_eq "" "$output" "output should be empty when failing"
    rm -f $err_file2

    # 後始末
    rm -f "$safe_file"
end

function test_totp_show_fails_for_unknown_site
    set -l err_file (mktemp)
    totp_show nosuchsite >/dev/null 2>$err_file
    set -l s $status
    assert_failure $s "totp_show should fail for unknown site"
    assert_match 'unknown site' (cat $err_file) "stderr should contain 'unknown site' for missing site"
    rm -f $err_file
end

function test_totp_show_fails_without_arguments
    set -l err_file (mktemp)
    totp_show >/dev/null 2>$err_file
    set -l s $status
    assert_failure $s "totp_show should fail without arguments"
    assert_match 'error: site name is required' (cat $err_file) "stderr should report missing site name"
    rm -f $err_file
end

function test_totp_show_fails_without_jq
    printf '{"secret":"JBSWY3DPEHPK3PXP"}\n' >"$TOTP_DIR/github"
    set -l err_file (mktemp)
    _test_without_command jq totp_show github >/dev/null 2>$err_file
    set -l s $status
    assert_failure $s "totp_show should fail when jq is missing"
    assert_match 'jq is required' (cat $err_file) "should report missing jq in stderr"
    rm -f $err_file
end
