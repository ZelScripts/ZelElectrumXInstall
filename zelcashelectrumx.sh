#!/bin/bash
#A scrypt to install ZelCash ElectrumX Server on an existing ZelNode
#This scrypt will work on any VPS that meets the following minimum requirements:
#
#1.
#2.
#3.
#

#Version 1
#TESTING ONLY

###### please be logged in as a sudo user, not root #######

#Variables
USERNAME=$(who -m | awk '{print $1;}')
RPCUSER=`grep -r rpcuser= /home/goose/.zelcash/zelcash.conf | cut -d= -f2`
RPCPASSWORD=`grep -r rpcpassword= /home/goose/.zelcash/zelcash.conf | cut -d= -f2`
RPCPORT=`grep -r rpcallowip= /home/goose/.zelcash/zelcash.conf | cut -d= -f2`
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

#Output install Docker
echo -e "\033[1;33mInstalling Docker packages...\033[0m"
sleep 2

#Install docker
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io

#Verify docker installation with Hello world.
sudo docker run hello-world

#Output installation complete
echo -e "\033[1;33mDocker installation complete!\033[0m"
sleep 2

#Begin ZelCash ElectrumX Server Installation
echo -e "\033[1;33mInstalling ZelCash ElectrumX Server...\033[0m"
sleep 2

#Create docker subnet
sudo docker network create --subnet=172.18.0.0/16 myzelnet123

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
echo -e "\n\033[1;32mCreating Script to Execute Docker Container...\033[0m"
    sleep 3
    #Create data folder
    sudo mkdir /home/$USERNAME/zelcashelectrumx
    touch /home/$USERNAME/startelectrumx.sh
    echo "#!/bin/bash" >> ./startelectrumx.sh
    echo "sudo docker run --net myzelnet123 --ip 172.18.0.2 -v ~/zelcashelectrumx:/data -e DAEMON_URL=http://$RPCUSER:$RPCPASSWORD@172.18.0.1:16124 -e COIN=ZelCash -e MAX_SEND=20000000 -e CACHE_MB=2000 -e MAX_SESSIONS=5000 -e MAX_SUBS=500000 -e ALLOW_ROOT=1 -e RPC_HOST=127.0.0.1  -e SSL_PORT=50002 -p 50002:50002 thetrunk/electrumx" >> ./startelectrumx.sh
    sudo chmod +x /home/$USERNAME/startelectrumx.sh

#Open screen session with name zelcashElectrumx
screen -mS zelcashElectrumx /home/$USERNAME/startelectrumx.sh


