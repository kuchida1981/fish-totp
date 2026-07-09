complete -c totp -f -n "test (count (commandline -opc)) -eq 1" -a 'add remove ls show'
complete -c totp -f -n "test (count (commandline -opc)) -eq 1" -a '(ls $TOTP_DIR 2>/dev/null)'
complete -c totp -f -n "test (count (commandline -opc)) -eq 2; and contains -- (commandline -opc)[2] remove show" -a '(ls $TOTP_DIR 2>/dev/null)'
