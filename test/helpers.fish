# テスト用アサートヘルパー。test/run.fish から source される。
# テストケース関数は `test_` プレフィックスで命名すること（run.fish が自動収集する）。
# このファイル内のヘルパーは `_test_` プレフィックスにして、収集対象と衝突しないようにしている。

set -g __test_pass_count 0
set -g __test_fail_count 0
set -g __test_skip_count 0
set -g __current_test_name ""

function _test_report_pass
    set -g __test_pass_count (math $__test_pass_count + 1)
end

function _test_report_fail --argument-names detail
    set -g __test_fail_count (math $__test_fail_count + 1)
    echo "FAIL [$__current_test_name] $detail" >&2
end

function _test_report_skip --argument-names reason
    set -g __test_skip_count (math $__test_skip_count + 1)
    echo "SKIP [$__current_test_name] $reason" >&2
end

function assert_eq --argument-names expected actual message
    if test "$expected" = "$actual"
        _test_report_pass
    else
        _test_report_fail "$message (expected: '$expected', actual: '$actual')"
    end
end

function assert_status --argument-names expected actual message
    if test "$actual" -eq "$expected"
        _test_report_pass
    else
        _test_report_fail "$message (expected status: $expected, actual status: $actual)"
    end
end

function assert_success --argument-names actual message
    assert_status 0 "$actual" "$message"
end

function assert_failure --argument-names actual message
    if test "$actual" -ne 0
        _test_report_pass
    else
        _test_report_fail "$message (expected non-zero status, actual status: $actual)"
    end
end

function assert_match --argument-names pattern actual message
    if string match -rq -- "$pattern" "$actual"
        _test_report_pass
    else
        _test_report_fail "$message (expected to match: '$pattern', actual: '$actual')"
    end
end

# 各テストケース前後で TOTP_DIR を隔離するためのセットアップ/後始末。
function _test_setup_totp_dir
    set -g TOTP_DIR (mktemp -d)
end

function _test_teardown_totp_dir
    if set -q TOTP_DIR; and test -d "$TOTP_DIR"
        rm -rf "$TOTP_DIR"
    end
end

# jq/oathtool/python3 など、指定したコマンドを PATH 上から見えなくした状態で
# ブロックを実行するためのヘルパー。`command -sa` で PATH 上の全一致を検出し、
# それらが属するディレクトリすべてを「そのコマンドを除いた stub」に差し替える
# （同名バイナリが複数の PATH ディレクトリに存在するケースにも対応するため）。
function _test_without_command --argument-names cmd_name
    set -l real_paths (command -sa "$cmd_name")
    if test (count $real_paths) -eq 0
        return 1
    end
    set -l real_dirs
    for p in $real_paths
        set -a real_dirs (realpath (dirname "$p"))
    end

    set -l stub_root (mktemp -d)
    set -l new_path
    for entry in $PATH
        set -l resolved_entry (realpath "$entry" 2>/dev/null)
        if test -z "$resolved_entry"
            set resolved_entry "$entry"
        end
        if contains -- "$resolved_entry" $real_dirs
            set -l stub_dir "$stub_root"(string replace -a '/' '_' "$resolved_entry")
            mkdir -p "$stub_dir"
            ln -s $entry/* "$stub_dir/" 2>/dev/null
            rm -f "$stub_dir/$cmd_name"
            set -a new_path "$stub_dir"
        else
            set -a new_path "$entry"
        end
    end

    set -lx PATH $new_path
    $argv[2..]
    set -l result $status

    rm -rf "$stub_root"
    return $result
end
