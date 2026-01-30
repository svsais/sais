# Saki's Arch Install Script
#### Note this installer is for UEFI 64 bit systems, running an x86-64 architecture.
---


# Install Guide

>List internet devices (Skip if using ethernet)
```
> iwctl device list 
```

>If either the adapter or device are off: (Skip if using ethernet)
```
> iwctl device <name> set-property Powered on
> iwctl adapter <adapter> set-property Powered on
```

>Connect to the internet (Skip if using ethernet)
```
> iwctl --passphrase <passphrase> station <name> connect <SSID>
```

>Make sure you have internet connection (if you are connected it should return constant pings, ctrl + c to exit)
```
> ping google.com
```

>Download and run installer
```
> curl https://svsais.github.io/sais/ais.sh > /ais.sh && chmod +x /ais.sh && /ais.sh
```