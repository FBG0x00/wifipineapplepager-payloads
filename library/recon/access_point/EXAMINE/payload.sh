#!/bin/bash
# Title:       EXAMINE
# Description: While viewing an APs details, set the pager to monitor the APs channel or BSSID for a set amount of time or reset it to scan all channels.
# Author:      Septumus
# Version:     1.0

LOG "Please choose an option below:"
LOG ""
LOG green "A (GREEN) - RESET TO VIEW ALL CHANNELS AND AP"
LOG ""
LOG blue "UP - SET TO EXAMINE ONLY TARGET AP CHANNEL"
LOG ""
LOG orange "RIGHT - SET TO CHANNEL OF YOUR CHOICE"
LOG ""
LOG yellow "DOWN - SET TO EXAMINE ONLY TARGET AP BSSID"
LOG ""
LOG red "OTHER - EXIT"
LOG ""
LOG ""

button=$(WAIT_FOR_INPUT)

case ${button} in
    "A")
        PINEAPPLE_EXAMINE_RESET
        LOG "Pager has now been set to scan all channels."
        LOG ""
        LOG ""
        ;;
    "UP")
       channel="$_RECON_SELECTED_AP_CHANNEL"
       PROMPT "Cancel time entry to keep your channel selection until you reset it."
	seconds=$(NUMBER_PICKER "Seconds to monitor: " 7)
        LOG "CHANGING TO CHANNEL $channel..."
        LOG ""
        LOG ""
	PINEAPPLE_EXAMINE_CHANNEL $channel $seconds
		if [[ -z "$seconds" ]]; then
		LOG "Now watching only channel $channel until reset."
		else
		LOG "Now watching only channel $channel for $seconds seconds."
	    	fi
        LOG ""
        LOG ""        
        ;;
    "DOWN")
        bssid="${_RECON_SELECTED_AP_BSSID}"
        PROMPT "Cancel time entry to keep your BSSID selection until you reset it."
	seconds=$(NUMBER_PICKER "Seconds to monitor: " 7)
        LOG "CHANGING TO CHANNEL $_RECON_SELECTED_AP_SSID at $bssid..."
        LOG ""
        LOG ""
	PINEAPPLE_EXAMINE_BSSID $bssid $seconds
		if [[ -z "$seconds" ]]; then
       	LOG "Now watching only $_RECON_SELECTED_AP_SSID at $bssid until reset."
		else
		LOG "Now watching only $_RECON_SELECTED_AP_SSID at $bssid for $seconds seconds."
	    	fi
        LOG ""
        LOG ""        
        ;;
     "RIGHT")
        channel=$(NUMBER_PICKER "Channel to examine: " 7)
        PROMPT "Cancel time entry to keep your channel selection until you reset it."
	seconds=$(NUMBER_PICKER "Seconds to monitor: " 7)
        LOG "CHANGING TO CHANNEL $channel..."
        LOG ""
        LOG ""
	PINEAPPLE_EXAMINE_CHANNEL $channel $seconds
		if [[ -z "$seconds" ]]; then
		LOG "Now watching only channel $channel until reset."
		else
		LOG "Now watching only channel $channel for $seconds seconds."
	    	fi
        LOG ""
        LOG ""        
        ;;
     *) 
        LOG "User chose to exit."
        LOG ""
	LOG ""
        ;;
esac