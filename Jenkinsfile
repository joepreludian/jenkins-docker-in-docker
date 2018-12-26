pipeline {

    agent any;

    environment {
      DOCKER_AUTOYES = '1'
      DOCKER_PREFIX = "prl-testing-${env.BUILD_NUMBER}"
      DOCKER_PROJECT_PORT = '19001'
    }

    stages {
      stage('Running a smoke test') {
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
