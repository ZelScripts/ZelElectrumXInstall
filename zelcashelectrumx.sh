#!/bin/bash
#A scrypt to install ZelCash ElectrumX Server on an existing ZelNode
#This scrypt will work on any VPS that meets the following minimum requirements:
#
#1. OS - Ubuntu v16.04 or later
#2. Installed and synced ZelNode (Basic, Super, or BAMF)
#3. 
#

#Version 1
#TESTING ONLY

###### please be logged in as a sudo user, not root #######

#Variables
USERNAME=$(who -m | awk '{print $1;}')
RPCUSER=$(grep -a rpcuser= /home/$USERNAME/.zelcash/zelcash.conf | cut -d= -f2)
RPCPASSWORD=$(grep -a rpcpassword= /home/$USERNAME/.zelcash/zelcash.conf | cut -d= -f2)
RPCPORT=$(grep -a rpcallowip= /home/$USERNAME/.zelcash/zelcash.conf | cut -d= -f2)
CONFIG_FILE='zelcash.conf'
COIN_DAEMON='zelcashd'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
NC='\033[0m'
STOP='\e[0m'

#Functions
#countdown timer to provide outputs for forced pauses
#countdown "00:00:30" is a 30 second countdown
countdown()
(
  IFS=:
  set -- $*
  secs=$(( ${1#0} * 3600 + ${2#0} * 60 + ${3#0} ))
  while [ $secs -gt 0 ]
  do
    sleep 1 &
    printf "\r%02d:%02d:%02d" $((secs/3600)) $(( (secs/60)%60)) $((secs%60))
    secs=$(( $secs - 1 ))
    wait
  done
  echo -e "\033[1K"
)

clear
echo -e '\033[1;33m==========================================\033[0m'
echo -e 'ZelCash ElectrumX Server Setup, v1.0'
echo -e '\033[1;33m==========================================\033[0m'
echo -e '\033[1;34m25 May 2019, by Goose-Tech\033[0m'
echo -e
echo -e '\033[1;36mZelCash ElectrumX setup starting, press [CTRL-C] to cancel.\033[0m'
countdown "00:00:03"
echo -e

#Checks if user is logged in as root, if so, exits
if [ "$USERNAME" = "root" ]; then
    echo -e "\033[1;36mYou are currently logged in as \033[0mroot\033[1;36m, please log out and\nlog back in with the username you just created.\033[0m"
    exit
fi

#Output install prerequsite packages
echo -e "\033[1;33mInstalling packages to allow apt to use a repository over HTTPS...\033[0m"
sleep 3

#Update apt
sudo apt-get update

#Install packages to allow apt to use a repository over HTTPS:
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

#Output install Docker GPG key and repository
echo -e "\033[1;33mAdding offical Docker GPG key and repository...\033[0m"
sleep 2

#Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

#Verify last 8 digits of fingerprint key (9DC8 5822 9FC7 DD38 854A E2D8 8D81 803C 0EBF CD88)
sudo apt-key fingerprint 0EBFCD88

#Add stable repository
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

#Output install Docker & other dependencies
echo -e "\033[1;33mInstalling Docker packages...\033[0m"
sleep 2

#Install docker
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io screen

#Add user to docker
sudo usermod -aG $USERNAME docker

#Verify docker installation with Hello world.
docker run hello-world

#Output installation complete
echo -e "\033[1;32mDocker installation complete!\033[0m"
sleep 2

#Begin ZelCash ElectrumX Server Installation
echo -e "\033[1;33mInstalling ZelCash ElectrumX Server...\033[0m"
sleep 2

#Create docker subnet
docker network create --subnet=172.18.0.0/16 myzelnet123

#Stopping ZelCash daemon to modify zelcash.conf
echo -e "\033[1;33mUpdating zelcash.conf to allow IP address of docker container...\033[0m"
sudo systemctl stop zelcash > /dev/null 2>&1 && sleep 3
sudo zelcash-cli stop > /dev/null 2>&1 && sleep 5
sudo killall $COIN_DAEMON > /dev/null 2>&1

#Adding rpcallowip of docker container to zelcash.conf
sudo cp /home/$USERNAME/.zelcash/zelcash.conf /home/$USERNAME/.zelcash/zelcash.bak
echo "#Docker Subnet for ZelCash Electrum Server" >> /home/$USERNAME/.zelcash/$CONFIG_FILE
echo "rpcallowip=172.18.0.2/16" >> /home/$USERNAME/.zelcash/$CONFIG_FILE

#Opening port 16124 in firewall
sudo ufw allow 16124/tcp

#Restart zelcashd
sudo systemctl start zelcash
echo -e "\n\033[1;32mRestarting daemon...\033[0m"
countdown "00:00:30"

#Create script to execute docker in another screen
echo -e "\n\033[1;33mCreating Script to Execute Docker Container...\033[0m"
    sleep 3
    #Create data folder
    mkdir /home/$USERNAME/zelcashelectrumx
    touch /home/$USERNAME/startelectrumx.sh
    echo "#!/bin/bash" >> ./startelectrumx.sh
    echo "docker run --name=ZelCashElectrumX --net myzelnet123 --ip 172.18.0.2 -v /home/$USERNAME/zelcashelectrumx:/data -e DAEMON_URL=http://$RPCUSER:$RPCPASSWORD@172.18.0.1:16124 -e COIN=ZelCash -e MAX_SEND=20000000 -e CACHE_MB=2000 -e MAX_SESSIONS=5000 -e MAX_SUBS=500000 -e ALLOW_ROOT=1 -e RPC_HOST=127.0.0.1  -e SSL_PORT=50002 -p 50002:50002 --restart unless-stopped thetrunk/electrumx" >> ./startelectrumx.sh
    sudo chmod +x /home/$USERNAME/startelectrumx.sh
    #sudo chown -R $USERNAME:$USERNAME /home/$USERNAME/zelcashelectrumx

#Create system service to run docker container at startup
echo -e "\033[1;32mCreating system service file...\033[0m"
if [ -f /etc/systemd/system/docker-ZelCashElectrumX.service ]; then
    echo -e "\033[1;36mExisting service file found, backing up to ~/docker-ZelCashElectrumX.old ...\033[0m"
    sudo mv /etc/systemd/system/docker-ZelCashElectrumX.service ~/docker-ZelCashElectrumX.old;
fi
sudo touch /etc/systemd/system/docker-ZelCashElectrumX.service
cat << EOF > /etc/systemd/system/docker-ZelCashElectrumX.service
[Unit]
Description=ZelCashElectrumX service
Requires=docker.service
After=docker.service
[Service]
Restart=always
User=$USERNAME
Group=$USERNAME
WorkingDirectory=/home/$USERNAME/zelcashelectrumx
ExecStart=/usr/bin/docker start -a ZelCashElectrumX
ExecStop=/usr/bin/docker stop -t 2 ZelCashElectrumX
[Install]
WantedBy=multi-user.target
EOF
sudo chown root:root /etc/systemd/system/docker-ZelCashElectrumX.service
sudo systemctl daemon-reload
sleep 3
sudo systemctl enable docker-ZelCashElectrumX.service &> /dev/null

echo -e "\033[1;32mSetup complete.\033[0m"
sleep 3
echo -e "\n\033[1;33mReady to launch ZelCash ElectrumX Server...\033[0m"
sleep 2
echo -e "\n\033[1;33mCurrent block height is:\033[1;36m"
zelcash-cli getinfo | grep -a blocks | cut -d: -f2
echo -e "\n\033[1;33mWhen ElectrumX Server has reached the same block height,\033[m"
echo -e "\033[1;33muse \033[1;32m[CTRL-A]\033[1;33m then \033[1;32m[D]\033[1;33m to exit screen.\033[m"
echo -e "\n\033[1;32m"
read -n1 -r -p "Press any key to launch the server..." key
echo -e "\033[0m"
#Open screen session with name zelcashElectrumx and run startelectrumx.sh to launch
screen -mS zelcashElectrumx /home/$USERNAME/startelectrumx.sh


