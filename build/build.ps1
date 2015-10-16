param(
    $solution = '../Habitat.sln',
    $moduleFolder = '.'
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

$location = Get-Location
"Running from $location"

LoadModule "nuget" ".\$moduleFolder\nuget.psm1"
LoadModule "npm" ".\$moduleFolder\npm.psm1"
LoadModule "msbuild" ".\$moduleFolder\msbuild"

restoreNugetPackages($solution)
restoreNodeModules
buildSolution($solution)

UnloadModule "nuget"
UnloadModule "npm"
UnloadModule "msbuild"