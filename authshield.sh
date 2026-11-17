#!/bin/bash

# AuthShield
# Detect repeated failed SSH login attempts and optionally block the IP.

THRESHOLD=5
WINDOW="10 minutes ago"

# Require sudo/root privileges
if [[ $EUID -ne 0 ]]; then
    echo "Please run AuthShield with sudo:"
    echo "sudo ./authshield.sh"
    exit 1
fi

echo "================================"
echo "          AuthShield"
echo "================================"
echo
echo "Checking SSH failures from the last 10 minutes..."
echo

# Get failed SSH login events
FAILED_LOGS=$(journalctl -u ssh --since "$WINDOW" --no-pager | grep "Failed password")

# Stop if no failures exist
if [[ -z "$FAILED_LOGS" ]]; then
    echo "No failed SSH login attempts found."
    exit 0
fi

# Extract and count IP addresses
echo "$FAILED_LOGS" |
awk '{
    for (i=1; i<=NF; i++) {
        if ($i == "from") {
            print $(i+1)
        }
    }
}' |
sort |
uniq -c |
sort -nr > /tmp/authshield_counts.txt

# Check each IP
while read -r COUNT IP
do
    echo "IP Address: $IP"
    echo "Failed Attempts: $COUNT"

    if [[ $COUNT -ge $THRESHOLD ]]; then
        echo
        echo "WARNING: Suspicious SSH activity detected!"
        echo

        read -r -p "Block $IP from SSH? (y/n): " ANSWER < /dev/tty

        if [[ "$ANSWER" == "y" || "$ANSWER" == "Y" ]]; then

            if ufw status | grep -q "$IP"; then
                echo
                echo "$IP already has a firewall rule."
            else
                ufw insert 1 deny from "$IP" to any port 22 proto tcp
                echo
                echo "$IP has been blocked from SSH."
            fi

        else
            echo
            echo "No firewall rule was added."
        fi

    else
        echo "Below detection threshold."
    fi

    echo
done < /tmp/authshield_counts.txt
