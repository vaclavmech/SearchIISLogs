[cmdletbinding()]
param(
    [Parameter(
        Position = 0
    )]
    # c:\temp\u_ex170824.log
    $fileName,
    [Parameter(
        Position = 1
    )]
    [string] $searchText = "",
    [Parameter(
        Position = 2
    )]
    [string] $anotherText = "",
    [Parameter(
        Position = 3
    )]
    [bool] $formatted = $false
)

function Format-IISlog {
    param(
        $inputObject
    )
    $formattedResult = @()
    foreach ($item in $inputObject) {
        $item = $item.Split(" ")
        $formattedResult += [PSCustomObject] @{
            "date"              = $item[0]
            "time"              = $item[1]
            "s-ip"              = $item[2]
            "cs-method"         = $item[3]
            "cs-uri-stem"       = $item[4]
            "cs-uri-query"      = $item[5]
            "s-port"            = $item[6]
            "cs-username"       = $item[7]
            "c-ip"              = $item[8]
            "cs(User-Agent)"    = $item[9]
            "cs(Referer)"       = $item[10]
            "sc-status"         = $item[11]
            "sc-substatus"      = $item[12]
            "sc-win32-status"   = $item[13]
            "time-taken"        = $item[14]
        }
    }
    $formattedResult
}
function Format-ReceiveConnectorLogs {
    param(
        $inputObject
    )
    $formattedResult = @()
    foreach ($item in $inputObject) {
        $item = $item.Split(",")
        $formattedResult += [PSCustomObject] @{
            "date-time"         = $item[0]
            "connector-id"      = $item[1]
            "session-id"        = $item[2]
            "sequence-number"   = $item[3]
            "local-endpoint"    = $item[4]
            "remote-endpoint"   = $item[5]
            "event"             = $item[6]
            "data"              = $item[7]
            "context"           = $item[8]
        }
    }
    $formattedResult
}

$source = @"
using System;
using System.IO;
using System.Collections.Generic;
public static class MyClass{ 
    public static Object Process(string path, string text, string anotherText){
        List<String> result = new List<String>();
        using (StreamReader streamReader = File.OpenText(path)){    
            string item = String.Empty;
            while ((item = streamReader.ReadLine()) != null){
                if (item.Contains(text) && item.Contains(anotherText)) {
                    result.Add(item.Trim());
                    result.Add(System.Environment.NewLine);
                }
            }
        }
        return result;
    }
}
"@
try {
    Add-Type -TypeDefinition $source -Language CSharp
}
catch {
    # this is just to discard the exception :)
}

Write-Verbose "Processing $($filename).."

$result += [MyClass]::Process($fileName, $searchText, $anotherText)
if ($result.Count -eq 0) {
    Write-Verbose "Nothing found."
    exit
}
# split and remove spaces
$result = $result.Split("`n")
$result = $result.Trim()
# remove empty lines
$result = $result |Where-Object {$_}

if ($formatted) {
    if ($fileName -match "RECV") {
        $result = Format-ReceiveConnectorLogs($result)
    }elseif ($fileName -match "u_ex") {
        $result = Format-IISlog($result)
    }
}

$result

# example:
# PS F:\> gci c:\temp\*.log| select fullname | %{.\foo.ps1 -fileName $_.FullName -searchText mechhvac -anotherText "Active" -Verbose} >> export.txt
