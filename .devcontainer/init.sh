#!/bin/bash
set -e

# checkout the submodules
git submodule update --init --recursive

# restore the dotnet projects
dotnet restore projects/dotnet/DotnetProjects.sln
