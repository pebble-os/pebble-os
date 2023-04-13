#Disable NetBIOS by updating Registry
#http://blog.dbsnet.fr/disable-netbios-with-powershell#:~:text=Disabling%20NetBIOS%20over%20TCP%2FIP,connection%2C%20then%20set%20NetbiosOptions%20%3D%202
$key = "HKLM:SYSTEM\CurrentControlSet\services\NetBT\Parameters\Interfaces"
Get-ChildItem $key | ForEach-Object {
	Write-Host("Modify $key\$($_.pschildname)")
	$NetbiosOptions_Value = (Get-ItemProperty "$key\$($_.pschildname)").NetbiosOptions
	Write-Host("NetbiosOptions updated value is $NetbiosOptions_Value")
}
