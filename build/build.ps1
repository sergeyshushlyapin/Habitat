param(
    $solution = '../Habitat.sln',
    $moduleLocation = '.'
)

function LoadModule($moduleName, $modulePath)
{
    "Importing '$moduleName' from '$modulePath'"
    $error.clear()
    Import-Module $modulePath
    if($error.count -ge 1) {
        "Error importing module $moduleName"
        exit 1
    }
} 

function UnloadModule($moduleName)
{
    "Unloading $moduleName" 
    Remove-Module $moduleName 
}

LoadModule "nuget" "$moduleLocation\nuget.psm1"
LoadModule "npm" "$moduleLocation\npm.psm1"
LoadModule "msbuild" "$moduleLocation\msbuild"

restoreNugetPackages($solution)
restoreNodeModules
# buildSolution($solution)

UnloadModule "nuget"
UnloadModule "npm"
UnloadModule "msbuild"