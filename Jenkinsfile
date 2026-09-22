pipeline {

    agent any

    // environment {
    //     SERVER = "vagrant@192.168.56.20"
    //     REMOTE_DIR = "/home/vagrant/app"
    //     RELEASES_DIR = "/home/vagrant/releases"
    //     APP_PORT = "3000"
    //     HEALTH_URL = "http://localhost:3000/status"
    // }

    stages {

        stage("Install") {
            steps {
                echo "Instalação de dependências"

                dir("app") {
                    sh '''
                        set -eu

                        echo "Node:"
                        node --version

                        echo "NPM:"
                        npm --version

                        echo "Instalando dependências..."

                        npm ci
                    '''
                }
            }
        }

        stage("Build") {
            steps {
                echo "Etapa de Build"

                dir("app") {
                    sh '''
                        set -eu

                        echo "Executando build..."

                        npm run build
                    '''
                }
            }
        }

        stage("Test") {
            steps {
                echo "Etapa de Testes"

                dir("app") {
                    sh '''
                        set -eu

                        echo "Executando testes..."

                        npm test
                    '''
                }
            }
        }

        stage("Deploy") {
            steps {
                echo "Etapa de Deploy"

                sshagent(credentials: ["ssh_key"]) {
                    sh 'scp -r app/* vagrant@192.168.56.20:/home/vagrant/app/'
                }
            }
        }

    }

    post {

        success {
            echo "Pipeline executada com sucesso!"
        }

        failure {
            echo "Pipeline falhou!"
        }

        always {
            echo "Pipeline finalizada."
        }
    }
}
