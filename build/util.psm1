function RestoreNugetPackages($solution) {
    nuget restore $solution
}

function RestoreNodeModules(){
    npm install    
}

function BuildSolution($solution) {
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

function CleanExistingSiteRoot($publishTarget)
{
  "Removing Existing Website"
  $deleteTarget = $publishTarget + '\*'
  Remove-Item $deleteTarget -Force -Recurse
}

function CopyCleanSitecoreInstance($cmsRepository, $manifest, $publishTarget)
{
  $cmsDistro = $cmsRepository + '\' + $manifest.cmsVersion + '.zip'

  "Copying clean Website folder"
  $websiteFolderPath = $Manifest.cmsVersion+"\Website"
  Unzip -source $cmsDistro -target $publishTarget -folder $websiteFolderPath

  "Copying clean Data folder"
  $dataFolderPath = $Manifest.cmsVersion+"\Data"
  Unzip -source $cmsDistro -target $publishTarget -folder $dataFolderPath
}