# Disable PnP (plug and play) devices
$devices = @(
	'High precision event timer',
	'Microsoft Kernel Debug Network Adapter',
	'NDIS Virtual Network Adapter Enumerator',
)

Get-PnpDevice -FriendlyName $devices -ErrorAction Ignore | Disable-PnpDevice -Confirm:$false -ErrorAction Ignore
