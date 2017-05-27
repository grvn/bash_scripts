#!/bin/bash

cd "$(dirname "$0")" || exit;
. update.cfg
EX_IP=$(curl -s "ipecho.net/plain")
MY_IP=$(<update.ip)
NOW=$(date)
LOG='update.log'
MAXSIZE=250

# Verify that the parameter passed is an IP Address:
function is_IP() {
    if [ "$(echo "$1" | grep -o '\.' | wc -l)" -ne 3 ]; then
	echo "Parameter '$1' does not look like an IP Address (does not contain 3 dots).";
	return 1;
    elif [ "$(echo "$1" | tr '.' ' ' | wc -w)" -ne 4 ]; then
	echo "Parameter '$1' does not look like an IP Address (does not contain 4 octets).";
	return 1;
    else
	for OCTET in $(echo "$1" | tr '.' ' '); do
	    if ! [[ $OCTET =~ ^[0-9]+$ ]]; then
		echo "Parameter '$1' does not look like in IP Address (octet '$OCTET' is not numeric).";
		return 1;
	    elif [[ $OCTET -lt 0 || $OCTET -gt 255 ]]; then
		echo "Parameter '$1' does not look like in IP Address (octet '$OCTET' in not in range 0-255).";
		return 1;
	    fi
	done
    fi
    return 0;
}

function checklog() {
  if [ -f "$LOG" ]; then
    if [ "$(wc -l "$LOG" | cut -f1 -d' ')" -gt $MAXSIZE ]; then
      timestamp=$(date +%Y%m%d)
      newlogfile=$LOG.$timestamp
      mv $LOG "$newlogfile"
      > $LOG
      gzip -f -9 "$newlogfile"
    fi
    return 0;
  fi
  return 1;
}

if is_IP "$EX_IP"; then
  if [ "$MY_IP" != "$EX_IP" ]; then
    curl -s -k "https://ipv4.tunnelbroker.net/nic/update?username=$USER&password=$KEY&hostname=$TUNNEL&myip=$EX_IP" > /dev/null
    curl -s -k "https://dyn.dns.he.net/nic/update" -d "hostname=$HOST" -d "password=$DYNKEY" -d "myip=$EX_IP" > /dev/null
    printf "%s" "$EX_IP" > update.ip
    printf "%s --- Tunneln har uppdaterats, ny IP=%s\n" "$NOW" "$EX_IP" >> $LOG
    checklog;
  fi
fi
