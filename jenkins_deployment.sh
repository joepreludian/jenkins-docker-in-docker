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
  
  if [ -z "${DOCKER_PROJECT_MEMORY_USAGE}" ] 
  then 
    DOCKER_PROJECT_MEMORY_USAGE='1536m';
    echo " - DOCKER_PROJECT_PORT - using default"; 
  fi
  
  # Error handling
  if [ -n "${ERRORS_FOUND}" ] 
  then 
    echo -e "\nThere is errors. Please fex them before running it again";
    exit 1;
  fi
  
  DOCKER_VOLUME_JENKINS_HOME="${DOCKER_PREFIX}-vol-jenkins-home";
  DOCKER_VOLUME_JENKINS_CORE="${DOCKER_PREFIX}-vol-jenkins-core";
  
  echo " - DOCKER_PREFIX = ${DOCKER_PREFIX}";
  echo "    * DOCKER_VOLUME_JENKINS_HOME = ${DOCKER_VOLUME_JENKINS_HOME}";
  echo "    * DOCKER_VOLUME_JENKINS_CORE = ${DOCKER_VOLUME_JENKINS_CORE}";
  echo " - DOCKER_PROJECT_PORT = ${DOCKER_PROJECT_PORT}";
  echo " - JENKINS_DOCKER_IMAGE = ${JENKINS_DOCKER_IMAGE}";
  echo " - DOCKER_PROJECT_MEMORY_USAGE = ${DOCKER_PROJECT_MEMORY_USAGE}";

  if [ -z "${DOCKER_AUTOYES}" ]
  then
    echo -e "\n - Is that OK?"
    read
  else
    echo -e "\n - [DOCKER_AUTOYES SET]"
  fi

  echo;

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

function print_initial_admin_password {
  docker exec -it --user root $DOCKER_PREFIX cat /var/jenkins_home/secrets/initialAdminPassword | tr -d " \t\n\r";
}

function install_jenkins_container {

  JENKINS_URL=$(get_latest_war_version);

  echo "- NEW JENKINS WAR FILE: ${JENKINS_URL}";

  echo "Raising Jenkins Container";
  docker inspect $DOCKER_PREFIX || CREATE_DOCKER_INSTANCE=1;

  if [ -n "${CREATE_DOCKER_INSTANCE}" ]
  then
    echo "Creating instance...";
    docker run --restart=always -d -m $DOCKER_PROJECT_MEMORY_USAGE --name $DOCKER_PREFIX -v $DOCKER_VOLUME_JENKINS_HOME:/var/jenkins_home -v $DOCKER_VOLUME_JENKINS_CORE:/usr/share/jenkins -v /var/run/docker.sock:/var/run/docker.sock -it -p ${DOCKER_PROJECT_PORT}:8080 $JENKINS_DOCKER_IMAGE;
    
    echo "Waiting a little...";
    sleep 8;

    echo "Downloading latest jenkins war file into /usr/share/jenkins...";
    docker exec -it --user root $DOCKER_PREFIX wget $JENKINS_URL -O /usr/share/jenkins/jenkins.war;

    echo "Injecting Jenkins CLI...";
    inject_cli;

   echo "Restart container...";
    docker restart $DOCKER_PREFIX;

  fi
}

function inject_config {
    echo "Overriding the installer [NEW to RUNNING] on installStateName at config.xml...";
    docker exec -it --user root $DOCKER_PREFIX sed -i 's/<installStateName>NEW<\/installStateName>/<installStateName>RUNNING<\/installStateName>/g' /var/jenkins_home/config.xml
    
    echo "Injecting Environment variable where is located the jenkins_home docker volume...";
    docker exec -it --user root $DOCKER_PREFIX sed -i "s/<globalNodeProperties\/>/<globalNodeProperties><hudson.slaves.EnvironmentVariablesNodeProperty><envVars serialization=\"custom\"><unserializable-parents\/><tree-map><default><comparator class=\"hudson.util.CaseInsensitiveComparator\"\/><\/default><int>1<\/int><string>JENKINS_HOME_VOLUME<\/string><string>${DOCKER_VOLUME_JENKINS_HOME}<\/string><\/tree-map><\/envVars><\/hudson.slaves.EnvironmentVariablesNodeProperty><\/globalNodeProperties>/g" /var/jenkins_home/config.xml;

    echo "Restarting base container...";
    docker restart $DOCKER_PREFIX;
}

function inject_cli {
    docker exec -it --user root $DOCKER_PREFIX wget http://localhost:8080/jnlpJars/jenkins-cli.jar -O /usr/share/jenkins/jenkins_cli.jar;

    if [ $? -ne 0 ]
    then
      echo "An error occured... Trying again...";  # @todo add a rule to set a timeout;
      inject_cli;
    fi
}

function uninstall {
  review_configuration || exit $?;
  
  echo "Stopping and removing jenkins container and volumes...";
  docker stop $DOCKER_PREFIX; 
  docker rm $DOCKER_PREFIX; 
  docker volume rm $DOCKER_VOLUME_JENKINS_HOME $DOCKER_VOLUME_JENKINS_CORE;
}

#
# MAIN FUNCTION
#
function install {
  review_configuration || exit $1;
  
  
  echo -e "\nBeginning Installation..."
  echo "Pulling latest Jenkins docker image...";
  docker pull $JENKINS_DOCKER_IMAGE;

  echo "Raising Docker volumes...";
  raise_docker_volumes || exit $?;

  install_jenkins_container || exit $?;

  echo "Waiting 10s in order to wait for Jenkins to run...";
  sleep 10;

  inject_config;

  echo "Skipping install_plugins...";  #install_plugins;

  ADMIN_PASSWORD=$(print_initial_admin_password);
 
  echo;
  echo "Access your ip address at http://localhost:${DOCKER_PROJECT_PORT}/user/admin/configure and put the initial admin password...";
  echo "Username: admin";
  echo "Password: ${ADMIN_PASSWORD}";

  echo;

  echo "Enjoy your Jenkins!"
}

function install_plugins {
  ADMIN_PASSWORD=$(print_initial_admin_password);
  PLUGIN_LIST=$(cat jenkins_plugin_names | xargs echo);
  PLUGIN_AMOUNT=$(cat jenkins_plugin_names | wc -l);

  echo "Installing/Updating a list of ${PLUGIN_AMOUNT} plugins (according \"jenkins_plugin_names\" file)...";
  docker exec -it --user root $DOCKER_PREFIX java -jar /usr/share/jenkins/jenkins_cli.jar -http -s http://127.0.0.1:8080/ -auth admin:${ADMIN_PASSWORD} install-plugin $PLUGIN_LIST;

  echo "Restarting container...";
  docker restart $DOCKER_PREFIX;
}

function help {
  echo "Usage: $0";
}

echo "PRELUDIAN Jenkins Docker In Docker - Installer - version `cat VERSION`";
echo "----------------------------------------------------------------------";
echo;

if [ -z $1 ]
then
  help;
  echo;
  exit 1;
fi

# Perform the action
$1 || exit $?;

