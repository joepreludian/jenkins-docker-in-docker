pipeline {

    agent any;

    environment {
      DOCKER_AUTOYES = '1'
      DOCKER_PREFIX = "prl-testing"
      DOCKER_PROJECT_PORT = '19001'
      DOCKER_PROJECT_MEMORY_USAGE = '1024m'
    }

    options {
      disableConcurrentBuilds()
      buildDiscarder(logRotator(numToKeepStr: '5')) 
    }

    stages {

      stage('Cleanup check') {
        steps {

          sh "docker stop ${env.DOCKER_PREFIX} || true"
          sh "docker rm ${env.DOCKER_PREFIX} || true"
          sh "docker volume rm ${env.DOCKER_PREFIX}-vol-jenkins-home ${env.DOCKER_PREFIX}-vol-jenkins-core || true"

        }
      }

      stage('Smoke Install') {
        steps {
          cleanWs()
          checkout scm
          sh './jenkins_deployment.sh install'
        }
      }

      stage('Smoke Uninstall') {
        steps {
          sh './jenkins_deployment.sh uninstall'
        }
      }

      stage('Deployment stuff') {
        when {
          branch 'master'
        }
        steps {
          sh 'echo OK'
        }
      }

    }

}
