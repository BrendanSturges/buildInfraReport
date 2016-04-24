Function Get-FileName($initialDirectory){   
	[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
	$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
	$OpenFileDialog.initialDirectory = $initialDirectory
	$OpenFileDialog.filter = "All files (*.*)| *.*"
	$OpenFileDialog.ShowDialog() | Out-Null
	$OpenFileDialog.filename
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
	
	$chartIt.SaveImage("$Loc\$date\$domain\$server\$($server)_$($resName)_$($date).png","png")
}

$serverList = Get-Content -Path (Get-FileName)
$Loc = ""
$esx = ""

$date = Read-Host -Prompt "What's the date for the top level folder? (ex 2-19)"
Robocopy "$Loc\2-19" "$Loc\$date" /E /XF *.*

$start = (Get-Date).AddDays(-7)

$stat = @("cpu.usage.average", "mem.usage.average", "disk.usage.average", "net.usage.average")

Add-PSSnapin VMWare*

Connect-VIServer $esx

foreach($server in $serverList)
{
	$pingIt = ping $server -n 1
	$domain = $pingIt.Split('.')[2]
	Foreach($resource in $stat){
		$holder = Get-VM -name $server | Get-Stat -stat $resource -start $start
		$sDate = ($holder.timestamp).toShortDateString()
		$sTime = ($holder.timestamp).toShortTimeString()
		$resName = $resource.split('.')[0]
		$holder | Export-CSV "$Loc\$date\$domain\$server\$($server)_$($resName)_$($date).csv" -notypeinformation

		buildChart($blank)
	}
}