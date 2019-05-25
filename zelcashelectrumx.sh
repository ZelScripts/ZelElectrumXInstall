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
RPCUSER=grep rpcuser /home/$USERNAME/.zelcash/zelcash.conf
RPCPASSWORD=grep rpcpassword /home/$USERNAME/.zelcash/zelcash.conf
RPCPORT=grep rpcallowip /home/$USERNAME/.zelcash/zelcash.conf
CONFIG_FILE=/home/$USERNAME/.zelcash/zelcash.conf
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

#Create data folder
sudo mkdir /home/$USERNAME/zelcashelectrumx

#Create docker subnet
docker network create --subnet=172.17.0.0/16 mynet123

#Stopping ZelCash daemon to modify zelcash.conf
sudo systemctl stop zelcash > /dev/null 2>&1 && sleep 3
sudo zelcash-cli stop > /dev/null 2>&1 && sleep 5
sudo killall $COIN_DAEMON > /dev/null 2>&1

#Adding rpcallowip of docker container to zelcash.conf
echo "#Docker Subnet for ZelCash Electrum Server" >> ~/.zelcash/$CONFIG_FILE
echo "rpcallowip=172.17.0.2/16" >> ~/.zelcash/$CONFIG_FILE

#Create screen with name zelcashElectrumx
screen -mS zelcashElectrumx /home/$USERNAME/startelectrumx.sh


