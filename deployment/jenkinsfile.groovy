#!/usr/bin/env groovy

pipeline {

	agent any

	options { skipDefaultCheckout() }

	environment {
        AMI_NAME = 'true'
        DATE    = $(date +%Y-%m-%d)
				ASG_NAME = 'webserver'
  }

	stages {

		stage('GIT Checkout') {

			steps {
				deleteDir()
				checkout([
				                $class                           : 'GitSCM',
                				branches                         : [[name: "*/master"]],
                				doGenerateSubmoduleConfigurations: false,
                				extensions                       : [[$class: 'CleanCheckout']],
                				submoduleCfg                     : [],
                				userRemoteConfigs                : [[credentialsId: 'khanu-key', url: 'git@github.com:Gritit-PulseApp/jenkins.git']]
            			])

			}
		}

		stage('Composer Setup') {
			steps {
					dir('ansible') {
				sh '''
						AWS_PROFILE=staging ansible-playbook -i ec2.py setup_composer_staging.yml

				'''
					}
			}
		}
		stage('Deploy to Staging') {
			steps {
					dir('ansible') {
				sh '''
						AWS_PROFILE=staging ansible-playbook -i ec2.py gritit_deploy_staging.yml -e "release_branch=${release_branch}" -e "env=staging"
				'''
					}
			}
		}

		stage('Supervisor Setup') {
			steps {
					dir('ansible') {
				sh '''
						AWS_PROFILE=staging ansible-playbook -i ec2.py consumer_staging.yml --skip-tags "mq,tracker"
						AWS_PROFILE=staging ansible-playbook -i ec2.py mq_staging.yml --skip-tags "consumer,tracker"
						AWS_PROFILE=staging ansible-playbook -i ec2.py tracker_staging.yml --skip-tags "mq,consumer"
				'''
					}
			}
		}
		post {
			success{
				sh '''
					AMIID='aws ec2 create-image --instance-id $INSTANCE_ID --name "${AMI_NAME}_${release_version}-${DATE}" --description "${AMI_NAME}_${release_version} at ${DATE} UTC" --no-reboot |awk '{print $2}' | sed 's:^.\(.*\).$:\1:'`
					aws autoscaling create-launch-configuration --launch-configuration-name ${AMI_NAME}_${release_version}-${DATE}-LC --image-id ${AMI_ID} --instance-type m5.xlarge --key-name GorillaAPP --security-groups sg-09b1d76f1824c7e9c --instance-monitoring Enabled=true --no-associate-public-ip-address --ebs-optimized --block-device-mappings "[ { \"DeviceName\": \"/dev/sda1\", \"Ebs\": { \"VolumeSize\": 80,\"VolumeType\": \"gp2\" } }]" --user-data "sudo hostnamectl set-hostname ${AMI_NAME}"
					aws autoscaling update-auto-scaling-group --auto-scaling-group-name ${ASG_NAME} --launch-configuration-name ${AMI_NAME}_${release_version}-${DATE}-LC
				'''
			}
		}
	}
}
