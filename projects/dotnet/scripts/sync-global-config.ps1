# This script will sync the global level configuration settings to all the child repos

# set current working directory to where the script is called from
$PSScriptRoot = Split-Path -Parent $PSScriptRoot

# copy the Directory.Packages.props file to all the child repos as a Parent.Directory.Packages.props file
$globalConfigPath = "Directory.Packages.props"
$childConfigPath = "Parent.Directory.Packages.props"

# find all the child Directory.Packages.props files
$childConfigFiles = Get-ChildItem -Path . -Recurse -Filter $globalConfigPath

# copy the global Directory.Packages.props file to Parent.Directory.Packages.props allong side the existing Directory.Packages.props files
# excluding the global Directory.Packages.props file in the current working directory
foreach ($childConfigFile in $childConfigFiles) {
    if ($childConfigFile.DirectoryName -ne $PSScriptRoot) {
        $childConfigFileDirectory = $childConfigFile.DirectoryName
        $childConfigFilePath = Join-Path -Path $childConfigFileDirectory -ChildPath $childConfigPath
        Copy-Item -Path $globalConfigPath -Destination $childConfigFilePath -Force
        
        # copy the Common.*.props file to all the child repos as well
        Copy-Item -Path "Common.*.props" -Destination $childConfigFileDirectory -Force
        Copy-Item -Path "Package*.json" -Destination $childConfigFileDirectory -Force
        
        Write-Host "Synced global configuration to $childConfigFilePath"
    }
}

# replace the <BuiltInMonoRepo>true</BuiltInMonoRepo> with <BuiltInMonoRepo>false</BuiltInMonoRepo> in the Parent.Directory.Packages.props files
$builtInMonoRepo = "<BuiltInMonoRepo>true</BuiltInMonoRepo>"
$builtInMonoRepoReplacement = "<BuiltInMonoRepo>false</BuiltInMonoRepo>"
$childConfigFiles = Get-ChildItem -Path . -Recurse -Filter $childConfigPath

foreach ($childConfigFile in $childConfigFiles) {
    $childConfigFileContent = Get-Content -Path $childConfigFile.FullName
    $childConfigFileContent = $childConfigFileContent -replace $builtInMonoRepo, $builtInMonoRepoReplacement
    Set-Content -Path $childConfigFile.FullName -Value $childConfigFileContent
    Write-Host "Replaced BuiltInMonoRepo in $childConfigFile"
}

# copy the root .globalconfig.shared file to all the child repos overwriting the existing .globalconfig files
$globalConfigPath = ".globalconfig.shared"
$childConfigPath = ".globalconfig"

# find all the child .globalconfig files
$childConfigFiles = Get-ChildItem -Path . -Recurse -Filter $childConfigPath

# use the global .globalconfig.shared file to overwrite all the .globalconfig files
foreach ($childConfigFile in $childConfigFiles) {
    $childConfigFilePath = $childConfigFile.FullName
    Copy-Item -Path $globalConfigPath -Destination $childConfigFilePath -Force
    Write-Host "Synced global configuration to $childConfigFilePath"
}