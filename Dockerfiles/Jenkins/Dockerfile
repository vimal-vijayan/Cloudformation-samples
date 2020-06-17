FROM jenkins/jenkins:lts
USER root
RUN apt-get update && apt-get install -y maven python-pip python-dev \
&& pip install ansible==2.4.1.0