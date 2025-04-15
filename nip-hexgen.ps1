# Store all generated domains
$domains = @()

do {
    Clear-Host
    # Prompt for IP address (possibly with port)
    $ipInput = Read-Host "Enter an IPv4 address (e.g., 192.168.0.1 or 192.168.0.1:10000)"

    # Extract IP and optional port
    if ($ipInput -match '^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})(:(\d+))?$') {
        $ip = "$($Matches[1]).$($Matches[2]).$($Matches[3]).$($Matches[4])"
        $port = if ($Matches[6]) { ":$($Matches[6])" } else { "" }

        $octets = $ip -split '\.'
        $hex = ($octets | ForEach-Object { '{0:x2}' -f [int]$_ }) -join ''

        $prefix = Read-Host "Enter a subdomain prefix (e.g., fileshare)"
        $domain = "$prefix.$hex.nip.io"

        # Store the domain info
        $domains += [PSCustomObject]@{
            Basic = $domain
            HTTP = "http://$domain$port"
            HTTPS = "https://$domain$port"
        }

        $again = Read-Host "Would you like to enter another? (Y/N)"
    } else {
        Write-Host "Invalid IP address format. Please enter a valid IPv4 address (with optional :port)." -ForegroundColor Red
        $again = "Y"
        Pause
    }

} while ($again -match '^(Y|y)$')

# Output results
Write-Host "`nYour nip.io domains are:`n"

# Gray: BASIC
Write-Host "BASIC:" -ForegroundColor DarkGray
foreach ($d in $domains) {
    Write-Host $d.Basic -ForegroundColor DarkGray
}
Write-Host ""

# Yellow: HTTP
Write-Host "HTTP Domains:" -ForegroundColor Yellow
foreach ($d in $domains) {
    Write-Host $d.HTTP -ForegroundColor Yellow
}
Write-Host ""

# Green: HTTPS
Write-Host "HTTPS Domains:" -ForegroundColor Green
foreach ($d in $domains) {
    Write-Host $d.HTTPS -ForegroundColor Green
}
