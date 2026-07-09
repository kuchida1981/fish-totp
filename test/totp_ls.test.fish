function test_totp_ls_lists_files_under_totp_dir
    printf '{"secret":"AAAA"}\n' >"$TOTP_DIR/github"
    printf '{"secret":"BBBB"}\n' >"$TOTP_DIR/aws"

    set -l output (totp_ls | sort)
    assert_eq "aws github" "$output" "totp ls should list all site files under TOTP_DIR"
end

function test_totp_ls_empty_dir_outputs_nothing
    set -l output (totp_ls)
    assert_eq "" "$output" "totp ls should output nothing when TOTP_DIR has no files"
end
