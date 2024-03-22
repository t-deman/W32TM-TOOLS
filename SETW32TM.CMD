w32tm /config /manualpeerlist:"0.fr.pool.ntp.org","1.fr.pool.ntp.org","2.fr.pool.ntp.org","3.fr.pool.ntp.org" /syncfromflags:MANUAL /update /RELIABLE:YES
reg add HKLM\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\VMICTimeProvider /v Enabled /t reg_dword /d 0 /f
NET STOP W32TIME
NET START W32TIME
w32tm /resync /force