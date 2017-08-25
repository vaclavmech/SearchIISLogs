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
    [string] $anotherText = ""
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

Write-Verbose "Processing $($filename.FullName).."

[string]$result += [MyClass]::Process($fileName.FullName, $userName, $anotherText)
$result

# example:
# PS F:\> gci *.log| select fullname | %{.\foo.ps1 -fileName $_ -userName mechhvac -anotherText "Active" -Verbose} >> export.txt
