function restoreNugetPackages($solution) {
    nuget restore $solution
}

function restoreNodeModules(){
    npm install    
}

function buildSolution($solution) {
    msbuild `
      /t:Clean `
      /t:Build `
      /p:Configuration=release `
      /v:n `
      /nologo `
      /p:VisualStudioVersion=12.0 `
      $solution
}


function Unzip($source, $target, $folder)
{
  $shell = New-Object -ComObject Shell.Application
  $item = $shell.NameSpace("$source\$folder")
  $shell.NameSpace($target).CopyHere($item)
}