# ZelElectrumXInstall
zelcashelectrumx.sh - A bash script to assist in setup/creation of ZelCash ElectrumX Server in docker container on existing ZelNode

**NOTE:** This script is for MainNet ZelNodes.

**NOTE:** This installation guide is provided as is with no warranties of any kind.

**NOTE:** This version of the script (v1.0) adds docker repositories to apt and configures a docker subnet to run the ElectrumX server.

If you follow the steps and use a newly installed Ubuntu Server 18.04 VPS, it will assist in configuring and start your Node.

***
## Requirements
1) **VPS running Linux Ubuntu 18.04**
2) **SSH client such as [Putty](https://www.putty.org/)or [MobaXterm](https://mobaxterm.mobatek.net/)**

***
## Steps

1) **Connect to your VPS server console using PuTTY** terminal program, login as the user you created during ZelNode installation:

2) **Download scripts & begin installation of ZelNode**

**PLEASE BE SURE YOU ARE LOGGED IN AS YOUR USERNAME BEFORE RUNNING THESE SCRIPTS**

```
wget -O zelcashelectrumx.sh https://raw.githubusercontent.com/ZelScripts/ZelElectrumXInstall/master/zelcashelectrumx.sh && chmod +x zelcashelectrumx.sh && ./zelcashelectrumx.sh
```

**Follow instructions to run the install script**, which will install and configure docker for your node with all necessary options.

Then it will run ZelCash ElectrumX server in a separate screen.
To detach from the running screen session use:

```
[CTRL-A] then [D]
```
To return to the screen session use:
```
screen -r
```
To list all running screen sessions use:
```
screen -ls
```

***
__NOTE:__ This process may take anywhere from 5 to 10 minutes, depending on your VPS HW specs. ZelCashElectrumX container will restart automatically upon reboot.

Once the script completes, it will show the ZelCash ElectrumX Server running so you can verify that it has synced with the block chain. Take note of the block height displayed via the script or visit https://explorer.zel.cash/.
***
Special thanks to **Goose-Tech** and the **ZelCash Team** for debugging and assistance.
