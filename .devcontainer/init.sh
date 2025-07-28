#!/bin/bash
set -e

# checkout the submodules
git submodule update --init --recursive

# restore tools
dotnet tool restore
