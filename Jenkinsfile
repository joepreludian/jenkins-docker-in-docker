pipeline {

    agent any;

    environment {
      DOCKER_AUTOYES = '1'
      DOCKER_PREFIX = "prl-testing"
      DOCKER_PROJECT_PORT = '19001'
      DOCKER_PROJECT_MEMORY_USAGE = '1024m'
    }

    options {
      disableConcurrentBuilds(),
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

      stage('Testing') {
        steps {
          sh './jenkins_deployment.sh preflight_test'
        }
      }

      stage('Smoke Uninstall') {
        steps {
          sh './jenkins_deployment.sh uninstall'

          sh "if docker inspect ${env.DOCKER_PREFIX}; then; exit 1; else; exit 0; fi"
          sh "if docker volume inspect ${env.DOCKER_PREFIX}-vol-jenkins-home; then; exit 1; else; exit 0; fi"
          sh "if docker volume inspect ${env.DOCKER_PREFIX}-vol-jenkins-core; then; exit 1; else; exit 0; fi"
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
