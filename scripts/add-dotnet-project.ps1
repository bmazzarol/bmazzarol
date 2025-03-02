$projectName = Read-Host "Enter the name of the project"
$projectPath = "projects/dotnet/$projectName"

$PSScriptRoot = Split-Path -Parent $PSScriptRoot

git submodule add "https://github.com/bmazzarol/$projectName.git" $projectPath
