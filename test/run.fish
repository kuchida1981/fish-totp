#!/usr/bin/env fish
# 全テストを実行するエントリポイント。
# 使い方: fish test/run.fish
#
# test/*.test.fish 内で `test_` プレフィックスの関数として定義された
# テストケースを収集し、1件ずつ TOTP_DIR を隔離した状態で実行する。

set -l script_dir (dirname (status --current-filename))
set -l repo_root (dirname "$script_dir")

source "$script_dir/helpers.fish"

# functions/ 配下のプラグイン本体をロードする（fisher install なしでも
# コマンド挙動テストが実行できるように、直接 source する）。
for fn in "$repo_root"/functions/*.fish
    source "$fn"
end

for f in "$script_dir"/*.test.fish
    source "$f"
end

set -l test_functions (functions -a | string match -r '^test_.*' | sort)

if test (count $test_functions) -eq 0
    echo "No test functions found" >&2
    exit 1
end

for fn in $test_functions
    set -g __current_test_name "$fn"
    _test_setup_totp_dir
    $fn
    _test_teardown_totp_dir
end

set -l total (math $__test_pass_count + $__test_fail_count)
echo ""
echo "Tests: $total run, $__test_pass_count passed, $__test_fail_count failed"

if test $__test_fail_count -gt 0
    exit 1
end
exit 0
