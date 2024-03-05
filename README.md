# DynIPSet
## Description
Resolves fully qualified domain names to IP addresses and adds them to nftables sets. Combined with the timeout feature of nftables sets this script can be used to implement dynamic firewall rules for protecting communication between endpoints with dynamic IPs.
## Setup
Copy the configuration file *config.json* to /etc/dynipset/config.json, update the set names and add your own host(s).

Add IP sets to your nftables firewall:
```
table inet filter {
    set admin-4 {
        type ipv4_addr
        timeout 4h
    }

    set admin-6 {
        type ipv6_addr
        timeout 4h
    }
}
```
Take a look at the *systemd* subfolder if you want to run the script periodically using a systemd timer.
