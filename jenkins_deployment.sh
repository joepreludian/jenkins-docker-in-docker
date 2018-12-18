#!/bin/bash

JENKINS_DOCKER_IMAGE="jenkins/jenkins:lts"


function review_configuration {
  if [ -z "${DOCKER_PREFIX}" ] 
  then 
    ERRORS_FOUND=1; 
    echo " - DOCKER_PREFIX variable not set"; 
  fi
  
  if [ -z "${DOCKER_PROJECT_PORT}" ] 
  then 
    ERRORS_FOUND=1; 
    echo " - DOCKER_PROJECT_PORT variable not set"; 
  fi

  if [ -n "${ERRORS_FOUND}" ] 
  then 
    echo -e "\nThere is errors. Please fex them before running it again";
    exit 1;
  fi
}

function raise_docker_volumes {

  echo "Fetching docker Volumes...";

  docker volume inspect $DOCKER_VOLUME_JENKINS_HOME || CREATE_DOCKER_VOLUME_JENKINS_HOME=1;
  docker volume inspect $DOCKER_VOLUME_JENKINS_CORE || CREATE_DOCKER_VOLUME_JENKINS_CORE=1;

  if [ -n "${CREATE_DOCKER_VOLUME_JENKINS_HOME}" ]
  then
    echo "* Creating JENKINS_HOME Volume";
    docker volume create $DOCKER_VOLUME_JENKINS_HOME;
  fi

  if [ -n "${CREATE_DOCKER_VOLUME_JENKINS_CORE}" ]
  then
    echo "* Creating JENKINS_CORE Volume";
    docker volume create $DOCKER_VOLUME_JENKINS_CORE;
  fi
}

function get_latest_war_version {
  JENKINS_LATEST_VERSION=$(curl -q "https://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-war/maven-metadata.xml" | grep -oPm1 "(?<=<latest>)[^<]+");
  JENKINS_LATEST_VERSION_URL=$(echo "https://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-war/${JENKINS_LATEST_VERSION}/jenkins-war-${JENKINS_LATEST_VERSION}.war");

  echo $JENKINS_LATEST_VERSION_URL;
}

function install_jenkins_container {

  JENKINS_URL=$(get_latest_war_version);

  echo "- NEW JENKINS WAR FILE: ${JENKINS_URL}";

  echo "Raising Jenkins Container";
  docker inspect $DOCKER_PREFIX || CREATE_DOCKER_INSTANCE=1;

  if [ -n "${CREATE_DOCKER_INSTANCE}" ]
  then
    echo "Creating instance...";
    docker run --restart=always -d -m 1536M --name $DOCKER_PREFIX -v $DOCKER_VOLUME_JENKINS_HOME:/var/jenkins_home -v $DOCKER_VOLUME_JENKINS_CORE:/usr/share/jenkins -it -p ${DOCKER_PROJECT_PORT}:8080 $JENKINS_DOCKER_IMAGE;
    
    echo "Waiting a little...";
    sleep 8;

    echo "Downloading latest jenkins war file into /usr/share/jenkins...";
    docker exec -it --user root $DOCKER_PREFIX wget $JENKINS_URL -O /usr/share/jenkins/jenkins.war;

    echo "Getting Jenkins Cli ready...";
    docker exec -it --user root $DOCKER_PREFIX wget http://localhost:8080/jnlpJars/jenkins-cli.jar -O /usr/share/jenkins/jenkins_cli.jar;

    echo "Restarting base container...";
    docker restart $DOCKER_PREFIX;

    echo "Getting initial admin Password. Acess your ip address at http://localhost:${DOCKER_PROJECT_PORT} and put the initial admin password...";
    docker exec -it --user root $DOCKER_PREFIX cat /var/jenkins_home/secrets/initialAdminPassword;

    echo "Once you login, click to install the recommended plugins. Once you finished all the installation on the web interface, run this command again with the install_plugins command."

  fi
}

#
# MAIN FUNCTION
#
function install {
  DOCKER_VOLUME_JENKINS_HOME="${DOCKER_PREFIX}-vol-jenkins-home";
  DOCKER_VOLUME_JENKINS_CORE="${DOCKER_PREFIX}-vol-jenkins-core";
  
  echo " - DOCKER_PREFIX = ${DOCKER_PREFIX}";
  echo "    * DOCKER_VOLUME_JENKINS_HOME = ${DOCKER_VOLUME_JENKINS_HOME}";
  echo "    * DOCKER_VOLUME_JENKINS_CORE = ${DOCKER_VOLUME_JENKINS_CORE}";
  echo " - DOCKER_PROJECT_PORT = ${DOCKER_PROJECT_PORT}";
  echo " - JENKINS_DOCKER_IMAGE = ${JENKINS_DOCKER_IMAGE}";

  if [ -z "${DOCKER_AUTOYES}" ]
  then
    echo -e "\n - Is that OK?"
    read
  else
    echo -e "\n - [DOCKER_AUTOYES SET] - Performing unattended install"
  fi

  echo -e "\nBeginning Installation..."
  echo "Pulling latest Jenkins docker image...";
  docker pull $JENKINS_DOCKER_IMAGE;

  echo "Raising Docker volumes...";
  raise_docker_volumes || exit $?;

  install_jenkins_container || exit $?;
}

function install_plugins {
  echo "Install Plugins!";

  docker exec -it --user root $DOCKER_PREFIX java -jar /usr/share/jenkins/jenkins_cli.jar -s http://localhost:8080/ -remoting login --username joey --pasword 123456;
}

echo "PRELUDIAN Jenkins Docker In Docker - Installer"
echo "----------------------------------------------"

review_configuration || exit $?;
$1 || exit $?;

