function boot-windows --description "Restart straight into Windows (one time, via UEFI BootNext)"
    # Boot0004 = Windows Boot Manager on nvme0n1p1 (check with: efibootmgr)
    sudo efibootmgr --bootnext 0004 --quiet
    and systemctl reboot
end
