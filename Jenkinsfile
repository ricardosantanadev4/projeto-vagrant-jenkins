pipeline {

    agent any

    stages {

        stage("Install") {
            steps {
                echo "Instalação de dependências"

                dir("app") {
                    sh "npm install"
                }

                echo "Etapa Finalizada"
            }
        }

        stage("Build") {
            steps {
                echo "Etapa de Build"

                dir("app") {
                    sh "npm run build"
                }

                echo "Etapa Finalizada"
            }
        }

        stage("Test") {
            steps {
                echo "Etapa de Testes"

                dir("app") {
                    sh "npm test"
                }

                echo "Etapa Finalizada"
            }
        }

        stage("Deploy") {
            steps {
                echo "Etapa de Deploy"

                sshagent(credentials: ["ssh_key"]) {

                    sh '''
                        set -e

                        SSH_OPTS="-n -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o ConnectTimeout=10"

                        echo "Criando diretório remoto..."

                        ssh $SSH_OPTS vagrant@192.168.56.20 \
                            "mkdir -p /home/vagrant/app"

                        echo "Enviando aplicação..."

                        tar --exclude=node_modules -czf - -C app . | \
                            ssh -o StrictHostKeyChecking=no \
                                -o UserKnownHostsFile=/dev/null \
                                -o BatchMode=yes \
                                -o ConnectTimeout=10 \
                                vagrant@192.168.56.20 \
                                "tar -xzf - -C /home/vagrant/app"

                        echo "Instalando dependências de produção..."

                        ssh $SSH_OPTS vagrant@192.168.56.20 \
                            "cd /home/vagrant/app && npm install --omit=dev"

                        echo "Parando aplicação anterior..."

                        ssh $SSH_OPTS vagrant@192.168.56.20 \
                            "PID=\$(sudo lsof -t -i :3000); if [ -n \"\$PID\" ]; then sudo kill \$PID; fi"

                        sleep 2

                        echo "Iniciando aplicação..."

                        ssh $SSH_OPTS vagrant@192.168.56.20 \
                            "cd /home/vagrant/app && nohup npm start > app.log 2>&1 < /dev/null &"

                        echo "Aguardando aplicação iniciar..."

                        sleep 3

                        echo "Verificando aplicação..."

                        ssh $SSH_OPTS vagrant@192.168.56.20 \
                            "curl -f http://localhost:3000/status"

                        echo "Deploy concluído com sucesso!"
                    '''
                }

                echo "Etapa Finalizada"
            }
        }
    }

    post {
        success {
            echo "The Stages were a Success!"
        }

        failure {
            echo "The process has failed!"
        }
    }
}
