#!/bin/bash
#
# Usage: sh scanIPList.sh textFileWithIPS (Dont forget to set the jobCode value!!!)
# Caution: It will create the files on /root, change manually it if you want (jobDir var)

YELLOW='\033[0;33m'
GRAY='\033[0;37m'
GREEN='\033[1;32m'
RED='\033[1;31m'

jobCode="TESTJOBCODE"

groupDir=$(echo "${1}" | sed 's/\.txt$//g')
homeDir=$(echo ~)
jobDir="${homeDir}/${jobCode}"
baseDir="${jobDir}/${groupDir}"

mkdir "${jobDir}" "${baseDir}"

echo "\n${RED}We will use jobCode ${GREEN}${jobCode}${RED} and the following baseDir: ${GREEN}${baseDir}${GRAY}\n"

# Preventing ARP floods
echo "${YELLOW}Preventing ARP Floods...${GRAY}"
/sbin/sysctl -w net.ipv4.neigh.default.gc_thresh3=4096
/sbin/sysctl -w net.ipv4.neigh.default.gc_thresh2=2048
/sbin/sysctl -w net.ipv4.neigh.default.gc_thresh1=1024

cat ${1} | while read line; do
    echo "${YELLOW}Processing ${line}.${GRAY}"
    ip=$(echo ${line} | sed "s/\./_/g")
    ipDir="${baseDir}/${ip}"
    tcpDir="${baseDir}/${ip}/TCP"
    udpDir="${baseDir}/${ip}/UDP"

    mkdir "${ipDir}" "${tcpDir}" "${udpDir}"

    fastUDPScan="sudo nmap -Pn -sU -v -n -T3 -p 49,53,67,68,69,88,111,117,123,135,137,138,139,161,445,500,513,514,1027,1060,2049,5060,5353,31337,32770,32771,32772,32776,41524 --max-retries=2 -oA ${udpDir}/${ip}_fastUDP ${line}"
    regularUDPScan="sudo nmap -Pn -sU -sV -sC -v -n -T3 -p 7,9,13,49,53,67,68,69,88,111,117,123,135,137,138,139,161,177,259,427,445,500,513,514,520,523,631,750,1027,1060,1434,1604,1701,1720,1745,1812,2049,2171,2172,2173,2746,3847,4045,4569,5060,5353,7001,7145,17185,18233,18234,31337,32770,32771,32772,32776,41524 --max-retries=2 -oA ${udpDir}/${ip}_regularUDP ${line}"
    fullUDPScan="sudo nmap -Pn -sU -sV -sC -v -n -T3 -p1-65535 --max-retries=2 -oA ${udpDir}/${ip}_fullUDP ${line}"
    fastTCPScan="sudo nmap -Pn -T3 -F -v -n -oA ${tcpDir}/${ip}_fastTCP ${line}"
    regularTCPScan="sudo nmap -Pn -T3 -v -n -sV -sC --top-ports 3000 --version-all -oA ${tcpDir}/${ip}_regularTCP ${line}"
    fullTCPScan="sudo nmap -Pn -T3 -v -n -A -p- --version-all -oA ${tcpDir}/${ip}_fullTCP ${line}"

    screen -d -m -S "${ip}_fastUDP" ${fastUDPScan}
    screen -d -m -S "${ip}_fastTCP" ${fastTCPScan}
    screen -d -m -S "${ip}_regularUDP" ${regularUDPScan}
    screen -d -m -S "${ip}_regularTCP" ${regularTCPScan}
    screen -d -m -S "${ip}_fullUDP" ${fullUDPScan}
    screen -d -m -S "${ip}_fullTCP" ${fullTCPScan}
done

sleep 2
screen -ls
echo "${YELLOW}Finished!${GRAY}"
