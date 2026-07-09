function test_fisher_install
    if not command -q fisher
        _test_report_skip "fisher not installed, skipping install verification test"
        return 0
    end

    # NOTE: fisher install . は実際に ~/.config/fish/functions/ 等にファイルをコピーする副作用のあるコマンドです。
    # テスト開始前に関数のロードを正しく検証するため、既存の定義を一度消去します
    functions -e totp totp_add totp_ls totp_remove totp_show totp_version

    # リポジトリのルートを取得（このファイル test/install.test.fish の2階層上）
    set -l repo_root (dirname (dirname (status --current-filename)))

    # fisher install . はカレントディレクトリを変更する可能性があるため、repo_root に移動して実行
    pushd "$repo_root"
    fisher install .
    set -l install_status $status
    popd

    # fisher install の成否に関わらず、後続のテストが壊れないよう関数を必ず復元する
    for fn in "$repo_root"/functions/*.fish
        source "$fn"
    end

    assert_success $install_status "fisher install . should succeed"

    # インストール後、すべての関数がロードされていることを確認する
    functions -q totp; and functions -q totp_add; and functions -q totp_ls; and functions -q totp_remove; and functions -q totp_show; and functions -q totp_version
    assert_success $status "All totp functions should be loaded after fisher install"
end
