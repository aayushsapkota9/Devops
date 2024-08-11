pipeline {
    agent any
    environment {
        dockerImage = ''
        registry = 'aayushsapkota9/test_proj'
        registryCredential= 'dockerhub_creds'
    }
    stages {
        stage('Clone') {
            steps {
                git branch: 'main', url: 'https://github.com/aayushsapkota9/test_proj.git'
            }
        }
        stage('Build') {
            steps {
                script {
                    dockerImage = docker.build registry
                }
            }
        }
        stage('Push') {
            steps {
                script {
                    docker.withRegistry('',registryCredential)
                    {
                        dockerImage.push()
                    }
                }
            }
        }
    }
}
