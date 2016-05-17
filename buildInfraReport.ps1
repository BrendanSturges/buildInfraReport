Function Get-FileName($initialDirectory){   
	[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
	$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
	$OpenFileDialog.initialDirectory = $initialDirectory
	$OpenFileDialog.filter = "All files (*.*)| *.*"
	$OpenFileDialog.ShowDialog() | Out-Null
	$OpenFileDialog.filename
}

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

Function buildChart($blank){
	[void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms.DataVisualization")
	$chartIt = New-object System.Windows.Forms.DataVisualization.Charting.Chart
	$chartIt.Width = 600
	$chartIt.Height = 600
	$chartIt.BackColor = [System.Drawing.Color]::White
	[void]$chartIt.Titles.Add("$($server) - $($resname) - $($date)")
	$chartIt.Titles[0].Font = "segoeuilight,20pt"
	$chartIt.Titles[0].Alignment = "topLeft"
	$chartarea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
	$chartarea.Name = "ChartArea1"
	$chartarea.AxisX.Title="Date"
	$chartarea.AxisY.Title="Average Utilization"
	$chartIt.ChartAreas.Add($chartarea)

	[void]$chartIt.Series.Add("Metrics")
	
	$x = $holder.count
	while($x -gt 0){
		$shortStamp = $sDate[$x] + " " + $sTime[$x]
		$chartIt.Series["Metrics"].points.addxy([string]$shortStamp, [double]$holder.value[$x])	
		$x--
	}
	
	$chartIt.Series["Metrics"].BorderWidth = 3
	$chartIt.Series["Metrics"].chartarea = "ChartArea1"
	$chartIt.Series["Metrics"].color = "red"
	$chartIt.Series["Metrics"].ChartType = "Line"
	
	$chartIt.SaveImage("$folderLoc\$date\$domain\$server\$($server)_$($resName)_$($date).png","png")
}

$date = get-date -format MM-dd

$serverList = Get-Content -Path (Get-FileName)

$folderLoc = Get-Folder

$start = (Get-Date).AddDays(-7)

$stat = @("cpu.usage.average", "mem.usage.average", "disk.usage.average", "net.usage.average")

Add-PSSnapin VMWare*

Connect-VIServer $esx
$i = 0


foreach($server in $serverList)
{
	$j = 0
	$pingIt = ping $server -n 1
	$domain = $pingIt.Split('.')[2]
	$i++
	Write-Progress -id 1 -activity "Generating report for server: $server `($i of $($serverList.count)`)" -percentComplete ($i / $serverList.Count*100) 
	Foreach($resource in $stat){
		$j++
		Write-Progress -id 2 -parentid 1 -activity "Checking resource: $resource `($j of $($stat.count)`)" -percentComplete ($j / $serverList.Count*100)
		$holder = Get-VM -name $server | Get-Stat -stat $resource -start $start
		$sDate = ($holder.timestamp).toShortDateString()
		$sTime = ($holder.timestamp).toShortTimeString()
		$resName = $resource.split('.')[0]
		New-Item -ErrorAction Ignore -Path $folderLoc\$date\$domain\$server -ItemType directory | Out-Null
		$holder | Export-CSV "$folderLoc\$date\$domain\$server\$($server)_$($resName)_$($date).csv" -notypeinformation

		buildChart($blank) | Out-Null
	}
}
