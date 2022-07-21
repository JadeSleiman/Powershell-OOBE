$Call (scriptname) from (this script name)
invoke-expression -Command (scriptnamefilepath) 


Write-Host "4/13 Install .NET 3.5" -ScriptBlock {
	Copy-Item $source "\\ultrabean\technology\DEPLOYMENT_IMAGES\sxsWin10v21H1 c:\OOBE\sxs"
	Add-WindowsPackage -Online Enable-WindowsOptionalFeature -FeatureName "NetFx3" -All -LimitAccess "/source:C:\OOBE\sxs" -NoRestart
} 

Write-Host "5/13 Turn OFF IEll" -ScriptBlock {
	Add-WindowsPackage -Online -DisableFeature -FeatureName "Internet-Explorer-Optional-amd64" -NoRestart
}

Write-Host "6/13 Run SCCM Check-in Cycle" -ScriptBlock { 
	$UninstallKey = "\\root\ccm" -Path "sms_client" -TriggerSchedule "{00000000-0000-0000-0000-000000000121}" -NonInteractive 
	$UninstallKey = "\\root\ccm" -Path "sms_client" -TriggerSchedule "{00000000-0000-0000-0000-000000000003}" -NonInteractive 
	$UninstallKey = "\\root\ccm" -Path "sms_client" -TriggerSchedule "{00000000-0000-0000-0000-000000000001}" -NonInteractive 
	$UninstallKey = "\\root\ccm" -Path "sms_client" -TriggerSchedule "{00000000-0000-0000-0000-000000000021}" -NonInteractive 
	$UninstallKey = "\\root\ccm" -Path "sms_client" -TriggerSchedule "{00000000-0000-0000-0000-000000000022}" -NonInteractive 
	$UninstallKey = "\\root\ccm" -Path "sms_client" -TriggerSchedule "{00000000-0000-0000-0000-000000000031}" -NonInteractive 
	$UninstallKey = "\\root\ccm" -Path "sms_client" -TriggerSchedule "{00000000-0000-0000-0000-000000000113}" -NonInteractive 
	$UninstallKey = "\\root\ccm" -Path "sms_client" -TriggerSchedule "{00000000-0000-0000-0000-000000000026}" -NonInteractive 
	$UninstallKey = "\\root\ccm" -Path "sms_client" -TriggerSchedule "{00000000-0000-0000-0000-000000000027}" -NonInteractive 
	$UninstallKey = "\\root\ccm" -Path "sms_client" -TriggerSchedule "{00000000-0000-0000-0000-000000000032}" -NonInteractive 
	$UninstallKey = "\\root\ccm" -Path "sms_client" -TriggerSchedule "{00000000-0000-0000-0000-000000000114}" -NonInteractive 
	control smscfgrc
}

Write-Host "7/13 Add Status Info to Log File" -ScriptBlock {
	## reports whether .NET3.5 is enabled
	Add-WindowsPackage -Online Get-WindowsFeature Format-Table Get-ChildItem "NetFx3" C:\OOBE\OOBE_LOG.log
	## reports whether IEll is enabled
	Add-WindowsPackage -Online Get-WindowsFeature Format-Table Get-ChildItem "Internet-Explorer-Optional-amd64" C:\OOBE\OOBE_LOG.log
	## if TPM is found, report as "TPM Activated", otherwise report "TPM DISABLED"
	Start-Process -filepath C:\windows\system32\manage-bde.exe -ArgumentList "-status C: | find "TPM" && echo "TPM Activated" || echo "TPM DISABLED" >>C:\OOBE\OOBE_LOG.log" -Wait -Verb RunAs -WindowStyle Hidden
	Start-Process -filepath C:\windows\system32\manage-bde.exe -ArgumentList "-status C: | find "TPM" && echo "TPM Activated" >>C:\OOBE\OOBE_LOG.log || echo "TPM DISABLED" >>C:\OOBE\OOBE_LOG.log" -Wait -Verb RunAs -WindowStyle Hidden
	Get-Command OOBE_LOG.log 
	## add OS information to log file
	Get-ComputerInfo | gci -r -i *C:\OOBE\OOBE_LOG.log { select-string "OS Name"
	Get-ComputerInfo | gci -r -i *C:\OOBE\OOBE_LOG.log { select-string "OS Version"
	## add hardware information to log file
	Get-ComputerInfo | gci -r -i *C:\OOBE\OOBE_LOG.log { select-string "Total Physical Memory"
	Get-CimInstance -ClassName Win32_ComputerSystem -ClassName Win32_bios -Path "C:\OOBE\OOBE_LOG.log"
	Get-Disk | ft -AutoSize DeviceID,Model,MediaType,BusType,Size -Path "C:\OOBE\OOBE_LOG.log"
	Get-CimInstance -ClassName Win32_videocontroller Get-Name "C:\OOBE\OOBE_LOG.log"
	## add IP Address information to log file
	Get-NetIPAddress -filepath C:\OOBE\OOBE_LOG.log
	## I dont know how to code these last two lines 
	##:mshta vbscript:Execute("msgbox "%%":close")
	##msg %username% Log file updated. Please check the OOBE_LOG.log in C:\OOBE
}

Write-Host "8/13 Delete Temporary Files" -ScriptBlock {
	Remove-Item -Path C:\OOBE\sxs -r -f 
	Remove-Item -Path C:\Office2019basic -r -f 
}

Write-Host "9/13 Launch Windows Update" -ScriptBlock {
	Get-command -module PSWindowsUpdate
	Get-WUInstall –MicrosoftUpdate –AcceptAll –AutoReboot
	Get-wurebootstatus
	UsoClient StartScan
	UsoClient StartInstall
	UsoClient RestartDevice
	UsoClient ScanInstallWait
	Get-WUInstall –MicrosoftUpdate –AcceptAll –AutoReboot
}

Write-Host "10/13 Launch Adobe Acrobat DC" -ScriptBlock {
	"C:\Program Files (x86)\Adobe\Acrobat DC\Acrobat\Acrobat.exe"
}

Write-Host "12/13 Launch Device Manager" -ScriptBlock {
	"C:\Program Files\Microsoft Office\root\Office16\WINWORD.EXE"
}

Write-Host "11/13 Launch Word 2019" -ScriptBlock {
	devmgmt.msc
}

Write-Host "13/13 Restart Computer" -ScriptBlock {
	msg %username% * Message "After Restart, go to BIOS and disable the USB boot."
	msg %username% * Message "After disabling USB boot, log in to Windows and delete C:\OOBE and C:\Office2019basic if it exists."
	## The Office2019Basic folder will not delete if you do not close the Office Setup window once Office is done installing.
	Stop-Computer
}