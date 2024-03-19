$f=get-adforest
$dcs=$f.GlobalCatalogs |sort

$LG=(get-culture).name
$TimeDC=@()
$Date=date

#$dcs=$dcs | where {$_ -like "AD-*"}
write-host "DomainController; SourceTime; TypeTM; NTPIP; VMICTimeEnabled"

foreach ($dc in $dcs){
  $b=w32tm /query /computer:$DC /source
  $tm=w32tm /dumpreg /subkey:parameters /computer:$DC
  $temp=$tm | findstr /I "NtpServer"
  $t=$temp.split(" ",[system.stringsplitOptions]::RemoveEmptyEntries)
  $NtpServer=$t[2]
  $temp=$tm | findstr /I "Type"|findstr /I "REG_SZ"
  $t=$temp.split(" ",[system.stringsplitOptions]::RemoveEmptyEntries)
  $TypeTM=$t[2]
  $temp=reg query \\$DC\HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\VMICTimeProvider /v enabled
  $t=$temp.split(" ",[system.stringsplitOptions]::RemoveEmptyEntries)
  $VMICTimeEnabled=$t[3]

  if($LG -like "FR-fr"){
    $tm=w32tm /query /status /computer:$DC | findstr /B "ID"
    $t=$tm.split(" )") 
    $NTPIP=$t[9]
    }
  else
    {
    $tm=w32tm /query /status /computer:$DC | findstr /I "ReferenceID"
    $t=$tm.split(" )")
    $NTPIP=$t[5]
    }

  $tm=w32tm /dumpreg /subkey:Config /computer:$DC | findstr /I "AnnounceFlags"
  $t=$tm.split(" ",[system.stringsplitOptions]::RemoveEmptyEntries)
  $AnnounceFlags=$t[2]

  $Reliable=switch ($AnnounceFlags){
     0 {"Not a Time Server"}
     1 {"Always TS"}
     2 {"Automatic TS"}
     4 {"Always Reliable TS"}
     5 {'Always TS & TS Reliable'}
     8 {"Automatic Reliable TS"}
     10{'Automatic TS & TS Reliable'}
    }

   $os = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $DC
   $cdt =$os | Select-Object @{Name='ConvertedDateTime';Expression={$_.ConvertToDateTime($os.LocalDateTime)}}
   $dateTime=$cdt.ConvertedDateTime  
   $Date2=date
   $Correction=($Date2 - $date)
   $dateCorrigee=($dateTime - $Correction)
#  $temp=reg query \\$DC\HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\VMICTimeProvider /v InputProvider
#  $t=$temp.split(" ",[system.stringsplitOptions]::RemoveEmptyEntries)
#  $InputProvider=$t[3]

  write-host "$DC ; $b ; $TypeTM  ; $NTPIP ; $VMICTimeEnabled; $dateCorrigee"
  
  $TimeRow=[pscustomobject]@{
    DC=$DC
    DateTime=$DateCorrigee
    Source=$b
    TypeTM=$TypeTM
    NtpServer=$NtpServer
    VMICTimeEnabled=$VMICTimeEnabled
    NTPIP=$NTPIP
    AnnouncesFlag=$AnnounceFlags
    Reliable=$Reliable
#    InputProvider=$InputProvider
    }
  $TimeDC+=$TimeRow
 } 

echo $TimeDC |export-csv -path .\DCTimeSource.csv -delimiter ";" -encoding "ASCII" -notypeinformation
echo $TimeDC |out-gridview -title "NTP-TimeServers"

