#!/bin/sh


#***********FUNCTIONS START HERE*************#

Create_Private_AMI() { #*******Function creates new AMI*******#

local INSTANCE_ID=$1
local AMI_NAME=$2
local ASG_NAME=$3
IAM_Role="AmazonEC2SSMRole"

AMI_ID=`aws ec2 create-image --instance-id $INSTANCE_ID --name "${AMI_NAME}-${DATE}" --description "${AMI_NAME} at ${DATE} UTC" --no-reboot |awk '{print $2}' | sed 's:^.\(.*\).$:\1:'`
TESTID=`aws ec2 describe-images --image-ids $AMI_ID | grep pending | awk '{print $2}' | sed 's:^.\(.*\).$:\1:' | sed 's/.$//'`
while [ "$TESTID" = "pending" ]
do
    TESTID=`aws ec2 describe-images --image-ids $AMI_ID | grep pending | awk '{print $2}' | sed 's:^.\(.*\).$:\1:' | sed 's/.$//'`
    echo "waiting to complete AMI of $INSTANCE_ID"
    sleep 60
done
echo "FINISHED AMI"

  aws autoscaling create-launch-configuration --launch-configuration-name ${AMI_NAME}-${DATE}-LC --image-id ${AMI_ID} --instance-type m5.xlarge --key-name ProdPrivateServerKey --security-groups sg-09c9f8d8995285ecb --instance-monitoring Enabled=true --no-associate-public-ip-address  --ebs-optimized --block-device-mappings "[ { \"DeviceName\": \"/dev/sda1\", \"Ebs\": { \"VolumeSize\": 30, \"VolumeType\": \"gp2\" } }, { \"DeviceName\": \"/dev/sdb\", \"Ebs\": { \"VolumeSize\": 80, \"VolumeType\": \"gp2\" } }]" --iam-instance-profile ${IAM_Role}"

  echo "Launch-Config-Finished"
  aws autoscaling update-auto-scaling-group --auto-scaling-group-name ${ASG_NAME} --launch-configuration-name ${AMI_NAME}-${DATE}-LC
  echo "Updated-ASG with new LC"

}

Create_Public_AMI() { #*******Function creates new AMI*******#

local INSTANCE_ID=$1
local AMI_NAME=$2
local ASG_NAME=$3
IAM_Role="AmazonEC2SSMRole"

AMI_ID=`aws ec2 create-image --instance-id $INSTANCE_ID --name "${AMI_NAME}-${DATE}" --description "${AMI_NAME} at ${DATE} UTC" --no-reboot |awk '{print $2}' | sed 's:^.\(.*\).$:\1:'`
TESTID=`aws ec2 describe-images --image-ids $AMI_ID | grep pending | awk '{print $2}' | sed 's:^.\(.*\).$:\1:' | sed 's/.$//'`
while [ "$TESTID" = "pending" ]
do
    TESTID=`aws ec2 describe-images --image-ids $AMI_ID | grep pending | awk '{print $2}' | sed 's:^.\(.*\).$:\1:' | sed 's/.$//'`
    echo "waiting to complete AMI of $INSTANCE_ID"
    sleep 60
done
echo "FINISHED AMI"

  aws autoscaling create-launch-configuration --launch-configuration-name ${AMI_NAME}-${DATE}-LC --image-id ${AMI_ID} --instance-type t3.medium --key-name ProdPublicServerKey --security-groups sg-05bd9c1ade6bae887 --instance-monitoring Enabled=true --no-associate-public-ip-address  --ebs-optimized --block-device-mappings "[ { \"DeviceName\": \"/dev/sda1\", \"Ebs\": { \"VolumeSize\": 80, \"VolumeType\": \"gp2\" } }, { \"DeviceName\": \"/dev/sdb\", \"Ebs\": { \"VolumeSize\": 80, \"VolumeType\": \"gp2\" } }]" --iam-instance-profile ${IAM_Role}"

  echo "Launch-Config-Finished"
  aws autoscaling update-auto-scaling-group --auto-scaling-group-name ${ASG_NAME} --launch-configuration-name ${AMI_NAME}-${DATE}-LC
  echo "Updated-ASG with new LC"

}


#***********SCRIPT START HERE*************#

DATE=`date +%Y-%m-%d`

WEB_INSTANCE=$(aws ec2 describe-instances --query 'Reservations[*].Instances[*].{Instance:InstanceId,State:State.Name,AZ:Placement.AvailabilityZone,Name:Tags[?Key==`Name`]|[0].Value}' --filters 'Name=tag:Name,Values=Prod-webserver*' --output text | grep running | awk '!a[$3]++' | grep -i 'Mobile' | awk '{print $2}' | head -1 )

echo "$WEB_INSTANCE"

CONSUMER_INSTANCE=$(aws ec2 describe-instances --query 'Reservations[*].Instances[*].{Instance:InstanceId,State:State.Name,AZ:Placement.AvailabilityZone,Name:Tags[?Key==`Name`]|[0].Value}' --filters 'Name=tag:Name,Values=Prod-consumer*' --output text | grep running | awk '!a[$3]++' | grep -i 'AdminDev' | awk '{print $2}')

echo "$CONSUMER_INSTANCE"

TRACKER_INSTANCE=$(aws ec2 describe-instances --query 'Reservations[*].Instances[*].{Instance:InstanceId,State:State.Name,AZ:Placement.AvailabilityZone,Name:Tags[?Key==`Name`]|[0].Value}' --filters 'Name=tag:Name,Values=Prod-tracker*' --output text | grep running | awk '!a[$3]++' | grep -i 'Web' | awk '{print $2}')

echo "$TRACKER_INSTANCE"

MQ_INSTANCE=$(aws ec2 describe-instances --query 'Reservations[*].Instances[*].{Instance:InstanceId,State:State.Name,AZ:Placement.AvailabilityZone,Name:Tags[?Key==`Name`]|[0].Value}' --filters 'Name=tag:Name,Values=Prod-MqApp*' --output text | grep running | awk '!a[$3]++' | grep -i 'Telematics' | awk '{print $2}')

echo "$MQ_INSTANCE"

        if [ ! -z ${WEB_INSTANCE} ]; then

              AMI_NAME="Prod-Gritit-Web"
              ASG_NAME="Prod-webserver-ASG"
              Create_Private_AMI $WEB_INSTANCE $AMI_NAME $ASG_NAME
              #Update_ASG $AMI_NAME $AMI_ID $ASG_NAME  #**FUNCTION CALL**#
   	else
	      echo "Instance not found"
	fi


        if [ ! -z $CONSUMER_INSTANCE ]; then

              AMI_NAME="Prod-Gritit-Consumer"
              ASG_NAME="Prod-consumer-ASG"
	      Create_Private_AMI $CONSUMER_INSTANCE $AMI_NAME $ASG_NAME
        else
		echo "Instance not found"
	fi



          if [ ! -z $TRACKER_INSTANCE ]; then

                AMI_NAME="Prod-Gritit-Tracker"
                ASG_NAME="Prod-tracker-ASG"
  	            Create_Public_AMI $TRACKER_INSTANCE $AMI_NAME $ASG_NAME
          else
  		echo "Instance not found"
  	fi



        if [ ! -z $MQ_INSTANCE ]; then

              AMI_NAME="Prod-Gritit-Mq"
              ASG_NAME="Prod-MqApp-ASG"
              Create_Public_AMI $MQ_INSTANCE $AMI_NAME $ASG_NAME  #**FUNCTION CALL**#

        else
              echo "Instance not found"
        fi
