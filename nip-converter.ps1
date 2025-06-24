#------------------------------------------------------------------------------#
# Function: Convert‐InputToTraefik
#   Reads one input (IPv4 or nip.io URL), normalizes it, and outputs
#   the corresponding traefik.me hostname (with HTTP/HTTPS variants).
#------------------------------------------------------------------------------#
function Convert-InputToTraefik {
    param (
        [string]$Prompt = "Enter an IPv4 address (e.g. 192.168.0.1 or prefix.192.168.0.1), or a nip.io URL"
    )
    # Prompt user
    $rawInput = Read-Host $Prompt

    # Normalize to a URI so we always get clean .Host, .Port, .PathAndQuery, .Fragment
    if ($rawInput -notmatch '^https?://') {
        $rawInput = "http://$rawInput"
    }
    try {
        $uri = [uri]$rawInput
    } catch {
        Write-Host "  → Invalid URL or address format." -ForegroundColor Red
        return
    }

    $hostname = $uri.Host
    $port     = if (($uri.Port -ne 80) -and ($uri.Port -ne 443)) { ":$($uri.Port)" } else { "" }
    # capture anything after the host:port, including path, query and fragment
    $suffix   = "$($uri.PathAndQuery)$($uri.Fragment)"

    # Initialize
    $prefix = ""
    $ip     = ""

    # Case A: hex-encoded nip.io (e.g. prefix.c0a800cb.nip.io)
    if ($hostname -match '^(.+?)\.([0-9A-Fa-f]{8})\.nip\.io$') {
        $prefix = $Matches[1]
        $hex    = $Matches[2]

        # Split the 8-char hex into 4 two-char segments
        $octets = for ($i = 0; $i -lt $hex.Length; $i += 2) {
            [Convert]::ToInt32($hex.Substring($i, 2), 16)
        }
        $ip = $octets -join '.'
    }
    # Case B: decimal nip.io (e.g. prefix.192.168.0.1.nip.io)
    elseif ($hostname -match '^(.+?)\.((?:\d{1,3}\.){3}\d{1,3})\.nip\.io$') {
        $prefix = $Matches[1]
        $ip     = $Matches[2]
    }
    # Case C: subdomain.IP (e.g. prefix.192.168.0.1)
    elseif ($hostname -match '^(.+?)\.((?:\d{1,3}\.){3}\d{1,3})$') {
        $prefix = $Matches[1]
        $ip     = $Matches[2]
    }
    # Case D: just an IP (e.g. 192.168.0.1)
    elseif ($hostname -match '^((?:\d{1,3}\.){3}\d{1,3})$') {
        $ip = $Matches[1]
    }
    else {
        Write-Host "  → Could not parse an IPv4 or nip.io hostname." -ForegroundColor Red
        return
    }

    # Build the traefik.me domain
    $domain = if ($prefix) { "$prefix.$ip.traefik.me" } else { "$ip.traefik.me" }

    return [PSCustomObject]@{
        Basic = $domain
        HTTP  = "http://$domain$port$suffix"
        HTTPS = "https://$domain$port$suffix"
    }
}

#------------------------------------------------------------------------------#
# Function: ConversionMenu
#   Loop for converting multiple inputs, storing results in $results.
#   After each, asks whether to do another or return to main menu.
#------------------------------------------------------------------------------#
function ConversionMenu {
    $results = @()
    do {
        Clear-Host
        $entry = Convert-InputToTraefik
        if ($entry) {
            $results += $entry
            Write-Host "`nConverted:"
            Write-Host "  BASIC: $($entry.Basic)" -ForegroundColor DarkGray
            Write-Host "  HTTP : $($entry.HTTP)"  -ForegroundColor Yellow
            Write-Host "  HTTPS: $($entry.HTTPS)" -ForegroundColor Green
        }

        do {
            $choice = Read-Host "`nConvert another? (C) or Main Menu? (M)"
        } until ($choice -match '^[CcMm]$')

    } while ($choice -match '^[Cc]$')

    return $results
}

#------------------------------------------------------------------------------#
# Main Menu
#------------------------------------------------------------------------------#
function Show-MainMenu {
    while ($true) {
        do {
            Clear-Host
            Write-Host "=== traefik.me Converter ===" -ForegroundColor Cyan
            Write-Host "1) Convert IPv4 / nip.io addresses"
            Write-Host "2) Exit"
            $opt = Read-Host "Select an option (1 or 2)"
        } until ($opt -in '1','2')

        switch ($opt) {
            '1' {
                $allResults = ConversionMenu
                if ($allResults.Count) {
                    Write-Host "`nAll conversions complete:`n"
                    Write-Host "BASIC:"    -ForegroundColor DarkGray
                    $allResults | ForEach-Object { Write-Host "  $($_.Basic)" }
                    Write-Host "`nHTTP:"    -ForegroundColor Yellow
                    $allResults | ForEach-Object { Write-Host "  $($_.HTTP)" }
                    Write-Host "`nHTTPS:"   -ForegroundColor Green
                    $allResults | ForEach-Object { Write-Host "  $($_.HTTPS)" }
                    Read-Host "`nPress Enter to return to main menu"
                }
            }
            '2' { return }
        }
    }
}


# kick it off
Show-MainMenu
