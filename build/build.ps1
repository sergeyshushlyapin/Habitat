param(
    $solution = '../Habitat.sln'
)

function LoadModule($moduleName, $modulePath)
{
    "Importing $moduleName"
    if((Get-Module $moduleName) -eq $null) { 
        Import-Module $modulePath
    }
} 

function UnloadModule($moduleName)
{
    "Unloading $moduleName" 
    Remove-Module $moduleName 
}

LoadModule "nuget" ".\nuget.psm1"
LoadModule "npm" ".\npm.psm1"
LoadModule "msbuild" ".\msbuild"

restoreNugetPackages($solution)
restoreNodeModules
# buildSolution($solution)

UnloadModule "nuget"
UnloadModule "npm"
UnloadModule "msbuild"