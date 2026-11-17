# AuthShield

AuthShield is a small Bash-based security tool for Ubuntu Linux that detects repeated failed SSH login attempts and gives the administrator the option to block a suspicious IP address using the UFW firewall.

## Purpose

Linux already records failed SSH login attempts in its system logs. AuthShield makes that information easier to use by automatically reading recent SSH authentication events, grouping failed attempts by IP address, counting the failures, and displaying a warning when a set threshold is reached.

For this project, the default threshold is:

- 5 failed SSH login attempts
- Within the last 10 minutes

When the threshold is reached, AuthShield asks the administrator whether the suspicious IP address should be blocked.

## Requirements

AuthShield was developed and tested on Ubuntu Linux.

The system should have:

- Bash
- OpenSSH Server
- systemd / journalctl
- UFW firewall
- sudo privileges

## Installation

Install OpenSSH Server and UFW:

```bash
sudo apt update
sudo apt install openssh-server ufw -y
```

Allow SSH through the firewall:

```bash
sudo ufw allow 22/tcp
```

Enable UFW:

```bash
sudo ufw enable
```

Make the AuthShield script executable:

```bash
chmod +x authshield.sh
```

## Usage

Run AuthShield with sudo:

```bash
sudo ./authshield.sh
```

AuthShield will:

1. Read failed SSH login attempts from the last 10 minutes.
2. Extract the IP address associated with each failure.
3. Count the failures from each IP address.
4. Compare the count to the detection threshold.
5. Display a warning if the threshold is reached.
6. Ask whether the suspicious IP address should be blocked.

Example:

```text
================================
          AuthShield
================================

Checking SSH failures from the last 10 minutes...

IP Address: 192.168.64.5
Failed Attempts: 5

WARNING: Suspicious SSH activity detected!

Block 192.168.64.5 from SSH? (y/n):
```

If the administrator chooses `y`, AuthShield adds a UFW rule that blocks SSH traffic from that IP address.

## Test Environment

The project uses two Ubuntu Linux virtual machines running in UTM.

- **Server VM:** Runs OpenSSH, AuthShield, journalctl, and UFW.
- **Client VM:** Generates controlled failed SSH login attempts.

The two VMs communicate through UTM's Shared Network.

## Testing

From the client VM, attempt to SSH into the server:

```bash
ssh username@SERVER_IP
```

Enter an incorrect password several times.

Then run AuthShield on the server:

```bash
sudo ./authshield.sh
```

If at least five failed attempts occurred within the last ten minutes, AuthShield should display a warning and offer to block the client's IP address.

To verify that the block worked, try connecting from the client VM again:

```bash
ssh -o ConnectTimeout=5 username@SERVER_IP
```

If the IP was successfully blocked, the SSH connection should fail instead of asking for a password.

## Removing a Block

To view the current UFW rules:

```bash
sudo ufw status numbered
```

Find the rule blocking the client IP address.

Then delete the rule using its rule number:

```bash
sudo ufw delete RULE_NUMBER
```

For example:

```bash
sudo ufw delete 1
```

This removes the block so the environment can be tested again.

## Related Tool

Fail2Ban is an existing security tool that also detects repeated authentication failures and can automatically ban offending IP addresses.

AuthShield is intentionally smaller and simpler. It focuses on failed SSH logins and requires administrator confirmation before an IP address is blocked.

## Project Topics Demonstrated

This project demonstrates:

- Linux authentication log analysis
- SSH administration
- Bash scripting
- UFW firewall management
- Virtual machine networking
- Security monitoring and response

## Author

Mihir Patel  
CPSC 4240/6240 – System Administration & Security
