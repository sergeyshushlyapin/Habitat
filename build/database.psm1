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

function GrantDatabaseAccess($dbNamePrefix, $username, $sqlServer)
{
    $roleName = "db_owner"
    $server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $sqlServer
    $database = $server.Databases[$dbNamePrefix+"_Web"]
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

 #    $server = (Get-Item sqlserver:\sql\localhost\DEFAULT -WarningAction SilentlyContinue)
 #    $database = $server.Databases[$databaseName]


	# $connection = new-object system.data.SqlClient.SqlConnection("Data Source=localhost;Integrated Security=SSPI;Initial Catalog=$databaseName");
	# $connection.Open()
	# Try {
	# 	$query ="if exists(select * from sys.database_principals where name = '$username') DROP USER [$username] if not exists(select * from sys.database_principals where name = '$username') CREATE USER [$username] FOR LOGIN [$username]"
	# 	TryExecuteQuery $query $connection
	    
	#     $query = "EXEC sp_addrolemember @rolename = N'db_owner', @membername = N'$username'"
	# 	TryExecuteQuery $query $connection
	# } finally {
 #    	$connection.Close()
	# }
}

function TryExecuteQuery($query, $connection){
	$command = new-object "System.Data.SqlClient.SqlCommand" ($query, $connection)

	#try 5 times with 3 seconds intervals
	$tries = 0
	$isExecuted = $false
	while ($isExecuted -eq $false){
		try {
			$tries++
			$command.ExecuteNonQuery() | out-null
			$isExecuted = $true
		} catch {
			#close-open connection solves the intermitent issue on connectivity
			$connection.Close()
			$connection.Open()
			if ($tries -eq 5){
				throw $_
			} else {
				Start-Sleep -Seconds 3
			}
		}
	}
}

function DetachDatabase($name)
{
    $server = (Get-Item sqlserver:\sql\localhost\DEFAULT -WarningAction SilentlyContinue)
    $database = $server.Databases[$name]
    if ($database -ne $null)
    {
        $server.KillAllProcesses($name)
        $database.Drop()
    }
}

function SetOffline($name)
{
    $server = (Get-Item sqlserver:\sql\localhost\DEFAULT -WarningAction SilentlyContinue)
    $database = $server.Databases[$name]
    if ($database -ne $null)
    {
        $server.KillAllProcesses($name)
        $database.SetOffline()
    }
}

function SetOnline($name)
{
    $server = (Get-Item sqlserver:\sql\localhost\DEFAULT -WarningAction SilentlyContinue)
    $database = $server.Databases[$name]

    if ($database -ne $null)
    {
        $database.SetOnline()
    }
}