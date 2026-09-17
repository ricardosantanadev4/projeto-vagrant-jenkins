pipeline {

    agent any

    stages {

        stage("Install") {
            steps {
                echo "Instalação de dependências"

                dir("app") {
                    sh "npm install"
                }
            }
        }

        stage("Build") {
            steps {
                echo "Etapa de Build"

                dir("app") {
                    sh "npm run build"
                }
            }
        }

        stage("Test") {
            steps {
                echo "Etapa de Testes"

                dir("app") {
                    sh "npm test"
                }
            }
        }

        stage("Deploy") {
            steps {
                echo "Etapa de Deploy"

                sshagent(credentials: ["ssh_key"]) {

                    sh '''
                        set -e

                        SSH_OPTS="-o StrictHostKeyChecking=no \
                                  -o UserKnownHostsFile=/dev/null \
                                  -o BatchMode=yes \
                                  -o ConnectTimeout=10"

                        SERVER="vagrant@192.168.56.20"
                        REMOTE_DIR="/home/vagrant/app"

                        echo "Testando conexão SSH..."

                        ssh $SSH_OPTS $SERVER "echo 'Conexão SSH estabelecida!'"

                        echo "Criando diretório remoto..."

                        ssh $SSH_OPTS $SERVER \
                            "mkdir -p $REMOTE_DIR"

                        echo "Limpando aplicação anterior..."

                        ssh $SSH_OPTS $SERVER \
                            "rm -rf $REMOTE_DIR/*"

                        echo "Enviando aplicação via SCP..."

                        scp $SSH_OPTS -r app/* \
                            $SERVER:$REMOTE_DIR/

                        echo "Instalando dependências de produção..."

                        ssh $SSH_OPTS $SERVER \
                            "cd $REMOTE_DIR && npm install --omit=dev"

                        echo "Parando aplicação anterior..."

                        ssh $SSH_OPTS $SERVER \
                            'PID=$(sudo lsof -t -i :3000); \
                             if [ -n "$PID" ]; then \
                                 sudo kill "$PID"; \
                             fi'

                        sleep 2

                        echo "Iniciando aplicação..."

                        ssh $SSH_OPTS $SERVER \
                            "cd $REMOTE_DIR && \
                             nohup npm start > app.log 2>&1 < /dev/null &"

                        echo "Aguardando aplicação iniciar..."

                        sleep 3

                        echo "Verificando aplicação..."

                        ssh $SSH_OPTS $SERVER \
                            "curl -f http://localhost:3000/status"

                        echo "Deploy concluído com sucesso!"
                    '''
                }
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
