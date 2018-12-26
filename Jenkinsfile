pipeline {

    agent any;

    environment {
      DOCKER_AUTOYES = '1'
      DOCKER_PREFIX = "prl-testing"
      DOCKER_PROJECT_PORT = '19001'
    }

    stages {

      stage('Cleanup check') {
        steps {

          docker_prefix = env.DOCKER_PREFIX
          docker_volume_home = "${docker_prefix}-vol-jenkins-home"
          docker_volume_core = "${docker_prefix}-vol-jenkins-core"

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
