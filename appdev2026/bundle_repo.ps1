$OutputFile = "gemini_context.txt"

# Clear the output file if it already exists, or create it
$null = New-Item -Path $OutputFile -ItemType File -Force

Write-Host "Generating repository map and bundling code..."

# Define the folders we want to ignore (regex format)
$SkipFolders = '\\build\\|\\.git\\|\\.dart_tool\\|\\linux\\|\\macos\\|\\windows\\|\\web\\|\\android\\|\\ios\\'

# Find all .dart and pubspec.yaml files, skip the ignored folders, and bundle them
Get-ChildItem -Path . -Recurse -File | Where-Object {
    ($_.Extension -eq ".dart" -or $_.Name -eq "pubspec.yaml") -and ($_.FullName -notmatch $SkipFolders)
} | ForEach-Object {
    # Get the relative path for cleaner reading
    $RelativePath = $_.FullName.Substring($PWD.Path.Length + 1)
    
    Add-Content -Path $OutputFile -Value "========================================"
    Add-Content -Path $OutputFile -Value "FILE PATH: $RelativePath"
    Add-Content -Path $OutputFile -Value "========================================"
    
    # Read the file and append its contents
    Get-Content $_.FullName -Raw | Add-Content -Path $OutputFile
    Add-Content -Path $OutputFile -Value "`n`n"
}

Write-Host "Done! Codebase bundled into $OutputFile"