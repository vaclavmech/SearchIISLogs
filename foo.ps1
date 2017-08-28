[cmdletbinding()]
param(
    [Parameter(
        Position = 0
    )]
    $fileName,
    [Parameter(
        Position = 1
    )]
    [string] $userName = "mechhvac",
    [Parameter(
        Position = 2
    )]
    [string] $anotherText = "",
    [Parameter(
        Position = 3
    )]
    [bool] $formatted = $false
)

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

$result += [MyClass]::Process($fileName, $userName, $anotherText)
# split and remove spaces
$result = $result.Split("`n")
$result = $result.Trim()
# remove empty lines
$result = $result |Where-Object {$_}

if ($formatted) {
    $formattedResult = @()
    foreach ($item in $result) {
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
}

if ($formatted) {
    $result = $formattedResult
}

$result

# example:
# PS F:\> gci c:\temp\*.log| select fullname | %{.\foo.ps1 -fileName $_.FullName -userName mechhvac -anotherText "Active" -Verbose} >> export.txt
