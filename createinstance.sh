#!/bin/bash

# name of the instance
Name=$1

# type of the instance
InstanceType=$2

# availability zone
AvailabilityZone=$3

# name of the key pair to use
KeyName=$4

# security group name
SGName=$5

# size of the volume to attach in GB
VolumeSize=$6

# name of the volume to attach
VolumeName=$7

# vpc id to use
VpcId=$8

# subnet id to use
SubnetId=$9

rm ./InstanceWithEBSTemplate.*
cp ./Orig_InstanceWithEBSTemplate.yml ./InstanceWithEBSTemplate.yml
pathtofile=./InstanceWithEBSTemplate.yml

#updating parameters
sed -i -e "s/replace_name/$Name/g" $pathtofile
sed -i -e "s/replace_instancetype/$InstanceType/g" $pathtofile
sed -i -e "s/replace_AZ/$AvailabilityZone/g" $pathtofile
sed -i -e "s/replace_keyname/$KeyName/g" $pathtofile
sed -i -e "s/replace_sgname/$SGName/g" $pathtofile
sed -i -e "s/replace_volumesize/$VolumeSize/g" $pathtofile
sed -i -e "s/replace_volumename/$VolumeName/g" $pathtofile
sed -i -e "s/replace_vpc_id/$VpcId/g" $pathtofile
sed -i -e "s/replace_subnet/$SubnetId/g" $pathtofile

# cat $pathtofile

# Creating the instance
aws cloudformation create-stack --stack-name $Name --template-body file://$pathtofile

# Checking the status
instanceIsRunning=0
counter=1
until [ "$instanceIsRunning" -eq 4 -o "$counter" -eq 18 ]
do
  sleep 10
  instanceIsRunning=$(aws cloudformation describe-stack-resources --stack-name $Name | grep CREATE | wc -l)
  echo Number of resources which are up: $instanceIsRunning
  echo This was check No. $counter
  let "counter++"		
done

# Getting the public DNS name of the new instance
publicDNS=$(aws ec2 describe-instances --instance-ids $(aws cloudformation describe-stack-resources --stack-name \
$Name | grep Physical |  grep i- | cut -c 36- | rev | cut -c 3- | rev) | grep PublicDns | head -1 | cut -c 39- | rev | cut -c 3- | rev)
echo "This is the public DNS: $publicDNS"

sgid=$(aws cloudformation describe-stack-resources --stack-name $Name | grep Physical |  grep sg- | cut -c 36- | rev | cut -c 3- | rev )
echo $sgid

# opening port 80 for nginx
echo "Port 80 will be opened on the new instance for all IP addresses!"
aws ec2 authorize-security-group-ingress --group-id $sgid --protocol tcp --port 80 --cidr 0.0.0.0/0

# waiting 1 minute for the instance to start some services like ssh
echo "Sleeping 1 minute, waiting for ssh to come up."
sleep 60

keyfile=$KeyName".pem"

# install nginx
ssh -o "StrictHostKeyChecking no" -i $keyfile  ec2-user@$publicDNS 'sudo amazon-linux-extras install nginx1 -y'
# create Hello world file and start nginx
ssh -o "StrictHostKeyChecking no" -i $keyfile ec2-user@$publicDNS 'sudo mv /usr/share/nginx/html/index.html /usr/share/nginx/html/index.html.orig'
ssh -o "StrictHostKeyChecking no" -i $keyfile ec2-user@$publicDNS 'echo "Hello World" > index.html'
ssh -o "StrictHostKeyChecking no" -i $keyfile ec2-user@$publicDNS 'sudo mv index.html /usr/share/nginx/html'
ssh -o "StrictHostKeyChecking no" -i $keyfile ec2-user@$publicDNS 'sudo service nginx start'
