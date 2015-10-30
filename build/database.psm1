function CopyDatabaseFiles($cmsRepository, $manifest, $dbDataLocation, $tempDir, $dbNamePrefix)
{
  $cmsDistro = $cmsRepository + '\' + $manifest.cmsVersion + '.zip'

  "Copying Database files folder from: '" + $cmsDistro + "', To: '" + $dbDataLocation + "'"
  $dataFilePath = $Manifest.cmsVersion+"\Databases"
  Unzip -source $cmsDistro -target $tempDir -folder $dataFilePath
  rename-item -path $tempDir"\Databases\Sitecore.Web.MDF" -newname $dbNamePrefix"_Web.MDF"
  rename-item -path $tempDir"\Databases\Sitecore.Web.LDF" -newname $dbNamePrefix"_Web.LDF"
  rename-item -path $tempDir"\Databases\Sitecore.Master.LDF" -newname $dbNamePrefix"_Master.LDF"
  rename-item -path $tempDir"\Databases\Sitecore.Master.MDF" -newname $dbNamePrefix"_Master.MDF"
  rename-item -path $tempDir"\Databases\Sitecore.Core.MDF" -newname $dbNamePrefix"_Core.MDF"
  rename-item -path $tempDir"\Databases\Sitecore.Core.LDF" -newname $dbNamePrefix"_Core.LDF"
  rename-item -path $tempDir"\Databases\Sitecore.Analytics.MDF" -newname $dbNamePrefix"_Analytics.MDF"
  rename-item -path $tempDir"\Databases\Sitecore.Analytics.LDF" -newname $dbNamePrefix"_Analytics.LDF"
  rename-item -path $tempDir"\Databases\Sitecore.Sessions.MDF" -newname $dbNamePrefix"_Sessions.MDF"
  rename-item -path $tempDir"\Databases\Sitecore.Sessions.LDF" -newname $dbNamePrefix"_Sessions.LDF"
  CopyFiles -sourceFiles $tempDir"\Databases\*" -publishTarget $dbDataLocation
}

function AttachAllDatabases($dbNamePrefix, $dbDataLocation, $sqlServer)
{
    "Attaching Sitecore Databases"
    AttachDatabase -name $dbNamePrefix"_Web" -mdfFile $dbDataLocation"\"$dbNamePrefix"_Web.MDF" -ldfFile $dbDataLocation"\"$dbNamePrefix"_Web.LDF" -sqlServer $sqlServer
    AttachDatabase -name $dbNamePrefix"_Master" -mdfFile $dbDataLocation"\"$dbNamePrefix"_Master.MDF" -ldfFile $dbDataLocation"\"$dbNamePrefix"_Master.LDF" -sqlServer $sqlServer
    AttachDatabase -name $dbNamePrefix"_Core" -mdfFile $dbDataLocation"\"$dbNamePrefix"_Core.MDF" -ldfFile $dbDataLocation"\"$dbNamePrefix"_Core.LDF" -sqlServer $sqlServer
    AttachDatabase -name $dbNamePrefix"_Analytics" -mdfFile $dbDataLocation"\"$dbNamePrefix"_Analytics.MDF" -ldfFile $dbDataLocation"\"$dbNamePrefix"_Analytics.LDF" -sqlServer $sqlServer
    AttachDatabase -name $dbNamePrefix"_Sessions" -mdfFile $dbDataLocation"\"$dbNamePrefix"_Sessions.MDF" -ldfFile $dbDataLocation"\"$dbNamePrefix"_Sessions.LDF" -sqlServer $sqlServer
}

function AttachDatabase($name, $mdfFile, $ldfFile, $sqlServer)
{
    "Attaching Database: " + $name
    $server = (Get-Item "sqlserver:\sql\$sqlServer" -WarningAction SilentlyContinue) 
    $owner = "sa"
    $sc = new-object System.Collections.Specialized.StringCollection
    $sc.Add($mdfFile) | out-null
    $sc.Add($ldfFile) | out-null
    $server.AttachDatabase($name, $sc, $owner, "None")
}

function CreateDbLogin($username, $password, $sqlServer)
{
    $server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $sqlServer
    if ($server.Logins.Contains($username))  
    {   
        Write-Host("Deleting the existing login: $username.")
           $server.Logins[$username].Drop() 
    }

    $login = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Login -ArgumentList $server, $username
    $login.LoginType = [Microsoft.SqlServer.Management.Smo.LoginType]::SqlLogin
    $login.PasswordExpirationEnabled = $false
    $login.PasswordPolicyEnforced  = $false
    $login.Create($password)
    "Login $username created successfully."
}

function SetupDbPermissions($dbNamePrefix, $username, $sqlServer)
{
  GrantDatabaseAccess -dbName $dbNamePrefix"_Analytics" -username $username -sqlServer $sqlServer
  GrantDatabaseAccess -dbName $dbNamePrefix"_Core" -username $username -sqlServer $sqlServer
  GrantDatabaseAccess -dbName $dbNamePrefix"_Master" -username $username -sqlServer $sqlServer
  GrantDatabaseAccess -dbName $dbNamePrefix"_Sessions" -username $username -sqlServer $sqlServer
  GrantDatabaseAccess -dbName $dbNamePrefix"_Web" -username $username -sqlServer $sqlServer
}

function GrantDatabaseAccess($dbName, $username, $sqlServer)
{
    $roleName = "db_owner"
    $server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $sqlServer
    $database = $server.Databases[$dbName]
    if ($database.Users[$username])
    {
        Write-Host("Dropping user $username on $database.")
        $database.Users[$username].Drop()
    }

    $dbUser = New-Object -TypeName Microsoft.SqlServer.Management.Smo.User -ArgumentList $database, $username
    $dbUser.Login = $loginName
    $dbUser.Create()
    Write-Host("User $dbUser created successfully.")

    #assign database role for a new user
    $dbrole = $database.Roles[$roleName]
    $dbrole.AddMember($username)
    $dbrole.Alter()
    Write-Host("User $dbUser successfully added to $roleName role.")
}