pipeline {

    agent any

    environment {
        SERVER = "vagrant@192.168.56.20"
        REMOTE_DIR = "/home/vagrant/app"
        RELEASE_DIR = "/home/vagrant/app-release"
        APP_PORT = "3000"
    }

    stages {

        stage("Install") {
            steps {
                echo "Instalação de dependências"

                dir("app") {
                    sh '''
                        set -e

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
                        set -e

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
                        set -e

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

                    sh '''
                        set -e

                        SSH_OPTS="-o StrictHostKeyChecking=no \
                                  -o UserKnownHostsFile=/dev/null \
                                  -o BatchMode=yes \
                                  -o ConnectTimeout=10"

                        SERVER="${SERVER}"
                        REMOTE_DIR="${REMOTE_DIR}"
                        RELEASE_DIR="${RELEASE_DIR}"
                        APP_PORT="${APP_PORT}"

                        echo "======================================"
                        echo "        INICIANDO DEPLOY"
                        echo "======================================"

                        echo ""
                        echo "1. Testando conexão SSH..."

                        ssh $SSH_OPTS "$SERVER" "echo 'Conexão SSH estabelecida!'"

                        echo ""
                        echo "2. Preparando diretório de release..."

                        ssh $SSH_OPTS "$SERVER" "
                            set -e

                            rm -rf '$RELEASE_DIR'
                            mkdir -p '$RELEASE_DIR'
                        "

                        echo ""
                        echo "3. Enviando aplicação..."

                        scp $SSH_OPTS -r app/* \
                            "$SERVER:$RELEASE_DIR/"

                        echo ""
                        echo "4. Instalando dependências de produção..."

                        ssh $SSH_OPTS "$SERVER" "
                            set -e

                            cd '$RELEASE_DIR'

                            npm ci --omit=dev
                        "

                        echo ""
                        echo "5. Validando arquivos da aplicação..."

                        ssh $SSH_OPTS "$SERVER" "
                            set -e

                            cd '$RELEASE_DIR'

                            test -f package.json
                            test -f server.js
                        "

                        echo ""
                        echo "6. Parando aplicação anterior..."

                        ssh $SSH_OPTS "$SERVER" '
                            set -e

                            PID=$(sudo lsof -t -i :'$APP_PORT' || true)

                            if [ -n "$PID" ]; then
                                echo "Processo encontrado: $PID"
                                echo "Enviando SIGTERM..."

                                sudo kill -TERM $PID || true

                                for i in $(seq 1 10); do

                                    if ! sudo kill -0 $PID 2>/dev/null; then
                                        echo "Processo encerrado."
                                        break
                                    fi

                                    echo "Aguardando processo terminar..."
                                    sleep 1
                                done

                                if sudo kill -0 $PID 2>/dev/null; then
                                    echo "Processo não terminou. Enviando SIGKILL..."
                                    sudo kill -KILL $PID || true
                                fi

                            else
                                echo "Nenhuma aplicação rodando na porta '$APP_PORT'."
                            fi
                        '

                        echo ""
                        echo "7. Instalando nova versão..."

                        ssh $SSH_OPTS "$SERVER" "
                            set -e

                            rm -rf '$REMOTE_DIR'
                            mkdir -p '$REMOTE_DIR'

                            cp -a '$RELEASE_DIR'/.' '$REMOTE_DIR'/

                            rm -rf '$RELEASE_DIR'
                        "

                        echo ""
                        echo "8. Iniciando aplicação..."

                        ssh $SSH_OPTS "$SERVER" "
                            cd '$REMOTE_DIR'

                            nohup npm start > app.log 2>&1 < /dev/null &
                        "

                        echo ""
                        echo "9. Aguardando aplicação iniciar..."

                        for i in \$(seq 1 15); do

                            echo "Health check - tentativa \$i/15"

                            if ssh $SSH_OPTS "$SERVER" \
                                "curl -fs http://localhost:$APP_PORT/status > /dev/null"
                            then
                                echo ""
                                echo "======================================"
                                echo "     APLICAÇÃO ESTÁ RESPONDENDO"
                                echo "======================================"
                                break
                            fi

                            if [ "\$i" -eq 15 ]; then

                                echo ""
                                echo "======================================"
                                echo "       FALHA NO HEALTH CHECK"
                                echo "======================================"

                                echo ""
                                echo "Logs da aplicação:"

                                ssh $SSH_OPTS "$SERVER" \
                                    "tail -n 100 '$REMOTE_DIR/app.log' || true"

                                echo ""
                                echo "Processos Node.js:"

                                ssh $SSH_OPTS "$SERVER" \
                                    "ps aux | grep '[n]ode' || true"

                                echo ""
                                echo "Porta $APP_PORT:"

                                ssh $SSH_OPTS "$SERVER" \
                                    "sudo lsof -i :$APP_PORT || true"

                                exit 1
                            fi

                            sleep 2
                        done

                        echo ""
                        echo "10. Validando processo..."

                        ssh $SSH_OPTS "$SERVER" \
                            "sudo lsof -i :$APP_PORT"

                        echo ""
                        echo "======================================"
                        echo "       DEPLOY CONCLUÍDO!"
                        echo "======================================"
                    '''
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
            echo "Verifique os logs da etapa que apresentou erro."
        }

        always {
            echo "Pipeline finalizada."
        }
    }
}
