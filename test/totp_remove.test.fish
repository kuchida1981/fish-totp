function test_totp_remove_deletes_existing_site
    # 既存の site ファイルを作成
    printf '{"secret":"JBSWY3DPEHPK3PXP"}\n' >"$TOTP_DIR/github"
    test -f "$TOTP_DIR/github"
    set -l exists $status
    assert_status 0 $exists "github file should exist initially"

    # 削除を実行
    totp_remove github
    set -l s $status
    assert_success $s "totp_remove github should exit successfully"

    # ファイルが削除されていることを確認
    test ! -f "$TOTP_DIR/github"
    set -l not_exists $status
    assert_status 0 $not_exists "github file should be deleted"
end

function test_totp_remove_rejects_path_traversal
    # 一時的な外部ファイルを作成
    set -l safe_file (mktemp)
    test -f "$safe_file"
    set -l exists $status
    assert_status 0 $exists "external safe file should exist initially"

    # / を含む site 名でエラー終了し、メッセージに 'unknown site' を含むことを確認
    set -l err_file (mktemp)
    totp_remove "foo/bar" >/dev/null 2>$err_file
    set -l s $status
    assert_failure $s "totp_remove with slash should fail"
    assert_match 'unknown site' (cat $err_file) "stderr should contain 'unknown site' for foo/bar"
    rm -f $err_file

    # 親ディレクトリや絶対パスのトラバーサルでのエラー確認
    set -l err_file2 (mktemp)
    totp_remove "$safe_file" >/dev/null 2>$err_file2
    set -l s2 $status
    assert_failure $s2 "totp_remove with absolute path should fail"
    assert_match 'unknown site' (cat $err_file2) "stderr should contain 'unknown site' for absolute path"
    rm -f $err_file2

    # 意図せぬファイル（safe_file）が削除されていないことを確認
    test -f "$safe_file"
    set -l safe_exists $status
    assert_status 0 $safe_exists "external safe file should not be deleted"

    # 後始末
    rm -f "$safe_file"
end

function test_totp_remove_fails_for_unknown_site
    set -l err_file (mktemp)
    totp_remove nosuchsite >/dev/null 2>$err_file
    set -l s $status
    assert_failure $s "totp_remove should fail for unknown site"
    assert_match 'unknown site' (cat $err_file) "stderr should contain 'unknown site' for missing site"
    rm -f $err_file
end

function test_totp_remove_fails_without_arguments
    set -l err_file (mktemp)
    totp_remove >/dev/null 2>$err_file
    set -l s $status
    assert_failure $s "totp_remove should fail without arguments"
    assert_match 'error: site name is required' (cat $err_file) "stderr should report missing site name"
    rm -f $err_file
end
