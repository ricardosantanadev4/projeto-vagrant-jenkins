pipeline {

    agent any

    environment {
        DEPLOY_HOST = '192.168.56.20'
        DEPLOY_USER = 'vagrant'
        DEPLOY_PATH = '/home/vagrant/app'
    }

    stages {

        stage("Install") {
            steps {
                echo 'Instalação de dependências'

                dir('app') {
                    sh 'npm install'
                }

                echo 'Etapa Finalizada'
            }
        }

        stage("Build") {
            steps {
                echo 'Etapa de Build'

                dir('app') {
                    sh 'npm run build'
                }

                echo 'Etapa Finalizada'
            }
        }

        stage("Test") {
            steps {
                echo 'Etapa de Testes'

                dir('app') {
                    sh 'npm test'
                }

                echo 'Etapa Finalizada'
            }
        }

        stage("Deploy") {
            steps {
                echo "Etapa de Deploy"

                sshagent(credentials: ["ssh_key"]) {

                    sh '''
                        set -e

                        SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o ConnectTimeout=10"

                        echo "Criando diretório remoto..."

                        ssh $SSH_OPTS vagrant@192.168.56.20 \
                            "mkdir -p /home/vagrant/app"

                        echo "Enviando aplicação..."

                        tar --exclude=node_modules -czf - -C app . | \
                            ssh $SSH_OPTS vagrant@192.168.56.20 \
                            "tar -xzf - -C /home/vagrant/app"

                        echo "Instalando dependências de produção..."

                        ssh $SSH_OPTS vagrant@192.168.56.20 \
                            "cd /home/vagrant/app && npm install --omit=dev"

                        echo "Parando aplicação anterior..."

                        ssh $SSH_OPTS vagrant@192.168.56.20 \
                            "cd /home/vagrant/app && \
                            if [ -f app.pid ]; then \
                                kill \$(cat app.pid) 2>/dev/null || true; \
                                rm -f app.pid; \
                            fi"

                        echo "Iniciando aplicação em background..."

                        ssh $SSH_OPTS vagrant@192.168.56.20 \
                            "cd /home/vagrant/app && \
                            setsid nohup npm start > app.log 2>&1 < /dev/null &"

                        echo "Deploy concluído!"
                    '''
                }

                echo "Etapa Finalizada"
            }
        }

    }

    post {
        success {
            echo 'Pipeline executado com sucesso!'
        }

        failure {
            echo 'O processo falhou!'
        }
    }
}