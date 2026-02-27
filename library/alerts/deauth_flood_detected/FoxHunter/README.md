# 🦊 FoxHunter

> **Deauth Flood Detection for the WiFi Pineapple Pager**
> Author: FBG0X00 | Version: 1.0

---

## Overview

FoxHunter is a passive deauthentication flood detection toolkit for the **WiFi Pineapple Pager** by Hak5. It comes in two scripts — one for use over SSH in a terminal, and one alert payload that runs directly on the Pagers hardware.

Neither script performs any active attacks. FoxHunter **only listens**.

---

## Scripts

| Script | Version | Use Case |
|---|---|---|
| `FoxHunter.sh` | 1.0 | Terminal-based monitor via SSH |
| `payload.sh` | 1.0 | Native Pager alert payload |

---

## FoxHunter.sh — Terminal Version

A full-featured deauth flood detector designed to be run over SSH. Captures packets passively, displays a live monitoring dashboard, and throws a full-screen alert when a flood is detected.

### Features

- Auto-detects monitor mode interface
- Live status dashboard with packet counts and alert history
- Full-screen terminal alert overlay on flood detection
- Top attacker MAC identification
- Timestamped event log saved to loot directory
- Audible beep alert on detection
- Clean shutdown with Ctrl+C
- Dependency check on startup

### Requirements

- WiFi Pineapple Pager (SSH access)
- Monitor mode interface (`wlan0mon` or equivalent)
- `tcpdump`, `iw`, `ip`, `awk`, `tput`

### Installation

Copy the script to your Pager to SSH or use SCP:

- Since you downloaded the file it should be in your Downloads Directory Example: /home/user/Downloads/payload.sh
- Use 'pwd' to find the path in your terminal.
```
#!/bin/bash

scp /home/user/Downloads/FoxHunter.sh root@172.16.42.1:/mmc/root/payloads/alerts/FoxHunter
```

Make it executable:

```
#!/bin/bash

chmod +x /root/FoxHunter.sh
```

### Configuration

Edit the variables at the top of the script before running:

```
#!/bin/bash

IFACE=""          # Leave blank to auto-detect, or set to "wlan0mon"
THRESHOLD=50      # Deauth packets per window before alerting
WINDOW_SIZE=30    # Detection window in seconds
LOG_DIR="/mmc/root/loot/foxhunter"   # Log directory (use /mmc/root/loot/ for SD card persistence)
ALERT_SOUND=true  # Audible beep on alert
MAX_LOG_LINES=500 # Max lines in packet log before trimming
```

> **Note on LOG_DIR:** If your Pager stores loot on the SD card, use `/mmc/root/loot/foxhunter`. If you want temp-only storage (faster, lost on reboot), use `/tmp/foxhunter`.

### Usage

```
#!/bin/bash

ssh root@172.16.42.1
bash /root/FoxHunter.sh
```

FoxHunter will auto-detect your monitor interface, start capturing, and display the live dashboard. When a deauth flood exceeds the threshold, a full-screen alert interrupts the terminal. Press **Enter** to dismiss and return to monitoring.

Press **Ctrl+C** to stop. The event log is saved automatically.

### Log Files

```
$LOG_DIR/events.log          # Timestamped alert and info log
$LOG_DIR/deauth_packets.txt  # Raw tcpdump packet capture (trimmed automatically)
```

---

## payload.sh — Native Pager Alert Payload

A lightweight native alert payload that integrates directly with the Pagers built-in PineAP recon engine. No capture loop needed — the Pager detects the flood and calls this script automatically.

### Features

- Triggered automatically by PineAPs deauth flood detection
- Full-screen `ALERT` notification on the Pagers physical display
- Triple-pulse vibration pattern for tactile alerting
- Alert ringtone plays automatically (firmware 1.0.5+)
- Logs all events with full MAC details to loot directory
- Exits fast — designed to be small and non-blocking

### How It Works

The Pagers PineAP recon engine monitors wireless traffic continuously. When it detects a deauthentication flood, it automatically runs all enabled payloads in the `deauth_flood_detected` category — including this one. The following details are passed automatically as environment variables:

| Variable | Description |
|---|---|
| `$_ALERT_DENIAL_SOURCE_MAC_ADDRESS` | MAC address of the attacking device |
| `$_ALERT_DENIAL_DESTINATION_MAC_ADDRESS` | Destination MAC |
| `$_ALERT_DENIAL_AP_MAC_ADDRESS` | Targeted access point MAC |
| `$_ALERT_DENIAL_CLIENT_MAC_ADDRESS` | Targeted client MAC |
| `$_ALERT_DENIAL_MESSAGE` | Human-readable event description |

### Installation

Copy the payload to the correct alerts directory on your Pager:

- Since you downloaded the file it should be in your Downloads Directory Example: /home/user/Downloads/payload.sh
- Use 'pwd' to find the path in your terminal.
```
#!/bin/bash

scp /home/user/Downloads/payload.sh root@172.16.42.1:/root/payloads/alerts/deauth_flood_detected/FoxHunter/
```

Or create the directory and file manually in SSH:

```
#!/bin/bash

mkdir -p /root/payloads/alerts/deauth_flood_detected/foxhunter/
```

### Enabling the Payload

1. On the Pager, open the **Dashboard**
2. Navigate to **Alerts**
3. Select the **deauth_flood_detected** category
4. Toggle **FoxHunter** on

### Configuration

```
#!/bin/bash

ENABLE_LOGGING=true
LOG_FILE="/mmc/root/loot/foxhunter_events.log"
```

> Set `ENABLE_LOGGING=false` to disable persistent logging.

### Log File

```
/mmc/root/loot/foxhunter_events.log   # Full event log with MACs and timestamps
```

---

## Loot Directory

Both scripts write logs to the Pagers loot directory. On Pagers with SD card storage, use:

```
/mmc/root/loot/foxhunter/
```

On Pagers without SD card, use:

```
/root/loot/foxhunter/
```

Logs can be reviewed at any time via SSH or the **Virtual Pager** browser interface.

---

## Legal

FoxHunter is a **passive detection tool only**. It does not transmit any packets, perform any attacks, or interfere with any wireless networks.

Only deploy on networks you own or have explicit written permission to monitor.

---

## Credits

Built for the **WiFi Pineapple Pager** by Hak5.

