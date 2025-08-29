# Run diskspd and capture XML
$xmlFile = "$env:COMPUTERNAME.xml"
.\diskspd.exe -b4K -d60 -o1 -t1 -r -w0 -Sh -L -Rxml #0 > $xmlFile

# Get active power scheme
$scheme = powercfg /GETACTIVESCHEME
if ($scheme -match 'GUID:\s+([0-9a-fA-F-]+)\s+\((.+)\)') {
    $guid = $matches[1]
    $name = $matches[2]
}

# Load XML and inject PowerScheme element
[xml]$doc = Get-Content $xmlFile

$powerNode = $doc.CreateElement("PowerScheme")
$powerNode.SetAttribute("Name", $name)
$powerNode.SetAttribute("Guid", $guid)

# Insert before <Tool> under <System>
$systemNode = $doc.Results.System
$toolNode   = $systemNode.Tool
$systemNode.InsertBefore($powerNode, $toolNode) | Out-Null

# Save back
$doc.Save($xmlFile)

Write-Host "Updated $xmlFile with PowerScheme Name=$name Guid=$guid"
