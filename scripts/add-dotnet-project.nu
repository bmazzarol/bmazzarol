# This script adds a new .NET project to the solution and updates the solution file.
# It takes the project name as an argument and creates a new .NET project with that name.
def main [
    # name of the project to be created
    projectName: string 
] {
    let projectPath = $'projects/dotnet/($projectName)'
    git submodule add $"https://github.com/bmazzarol/($projectName).git" $projectPath
}