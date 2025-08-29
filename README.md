DriveHealth.Maui
================

DriveHealth.Maui is a .NET MAUI app for browsing disk-health XML reports by 
Location.

You can see:
 - Each location with its worst (highest) average read latency (ms)
 - Each PC inside a location with its average read latency (ms)
 - A breakdown of all PC's in the summary tab

----------------------------------------------------------------------
Report Source
----------------------------------------------------------------------

The XML reports consumed by this app are generated using the **DiskSpd Storage 
Performance Tool**, a free benchmarking utility from Microsoft.

DiskSpd runs performance tests against storage devices and can export results 
in XML format. Those XML files are what DriveHealth.Maui parses and displays.

Official DiskSpd repository:
https://github.com/microsoft/diskspd

example DiskSpd command to generate XML report:

   ```
   # Run diskspd and capture XML
$xmlFile = "$env:COMPUTERNAME.xml"
.\diskspd.exe -b4K -d60 -o1 -t1 -r -w0 -Sh -L -Rxml '#0' > $xmlFile

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
   ```

   I set a scheduled task to run this command on each PC and copy the XML to a shared folder.

----------------------------------------------------------------------
XML INPUT FORMAT
----------------------------------------------------------------------

The XML output from DiskSpd contains:
 - ComputerName
 - RunTime (UTC preferred)
 - Latency -> AverageReadMilliseconds
 - Latency -> ReadLatencyStdev

----------------------------------------------------------------------
File Structure Example
----------------------------------------------------------------------

Place your reports in a root folder. Each subfolder represents a **location**, 
and each XML file inside represents a **PC**.

Example:

```
rootxml/
├─ 01-LOCATION/
│  ├─ LOCATION-PC01.xml
│  ├─ LOCATION-PC02.xml
│
├─ 02-LOCATION/
│  ├─ LOCATION-PC01.xml
│  ├─ LOCATION-PC02.xml
│
├─ 03-LOCATION/
│  ├─ LOCATION-PC01.xml
│
└─ 04-LOCATION/
   ├─ LOCATION-PC01.xml
   ├─ LOCATION-PC02.xml
```

In this structure:
 - "01-LOCATION" is a location
 - "LOCATION-PC01.xml" is a PC report inside that location

----------------------------------------------------------------------
Navigation Flow
----------------------------------------------------------------------

Locations Page:
   shows all locations with worst avg read latency.
   "Open" navigates to PCsInLocationPage.

Pcs In Location Page:
   shows all PCs with average read latency in a given location.

Summary Page:
   shows all PC's with read latency.

Settings Page:
   Pick where to read folders / xml files from.
