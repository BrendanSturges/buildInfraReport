Function Get-Folder($initialDirectory) {
    [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    [System.Windows.Forms.Application]::EnableVisualStyles()
    $browse = New-Object System.Windows.Forms.FolderBrowserDialog
    $browse.RootFolder = [System.Environment+SpecialFolder]'MyComputer'
    $browse.ShowNewFolderButton = $false
    $browse.Description = "Choose a directory"

    $loop = $true
    while($loop)
    {
        if ($browse.ShowDialog() -eq "OK")
        {
            $loop = $false
        } else
        {
            $res = [System.Windows.Forms.MessageBox]::Show("You clicked Cancel. Try again or exit script?", "Choose a directory", [System.Windows.Forms.MessageBoxButtons]::RetryCancel)
            if($res -eq "Cancel")
            {
                return
            }
        }
    }
    $browse.SelectedPath
    $browse.Dispose()
}

function getDeadlocks(){
	$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
	$SqlConnection.ConnectionString = "Server=$server;integrated security=true;Database=$db"
	$SqlConnection.Open()
	$SqlCmd = New-Object System.Data.SqlClient.SqlCommand
	$SqlCmd.CommandText = "SELECT cntr_value AS NumOfDeadLocks,* FROM sys.dm_os_performance_counters WHERE object_name = 'SQLServer:Locks' AND counter_name = 'Number of Deadlocks/sec' AND instance_name = '_Total'"
	$SqlCmd.Connection = $SqlConnection
	$dbt = $SqlCmd.ExecuteScalar()
	$SqlConnection.Close()

	return $dbt
}

$folderLoc = Get-Folder
$date = get-date -format MM-dd

#PROD
$server = ""
$db = ""

$holder = getDeadlocks | Out-File "$folderLoc\Prod_DeadLocks_$date.txt"

#DEV
$server = ""
$db = ""

$holder = getDeadlocks | Out-File "$folderLoc\DEV_DeadLocks_$date.txt"




