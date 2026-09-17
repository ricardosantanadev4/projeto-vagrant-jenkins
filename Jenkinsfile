pipeline {

    agent any

    environment {
        SERVER = "vagrant@192.168.56.20"
        REMOTE_DIR = "/home/vagrant/app"
        RELEASES_DIR = "/home/vagrant/releases"
        APP_PORT = "3000"
    }

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

                    sh '''
                        set -eu

                        SSH_OPTS="-o StrictHostKeyChecking=no \
                                  -o UserKnownHostsFile=/dev/null \
                                  -o BatchMode=yes \
                                  -o ConnectTimeout=10"

                        SERVER="${SERVER}"
                        REMOTE_DIR="${REMOTE_DIR}"
                        RELEASES_DIR="${RELEASES_DIR}"
                        APP_PORT="${APP_PORT}"

                        RELEASE_ID=$(date +%Y%m%d-%H%M%S)
                        RELEASE_DIR="${RELEASES_DIR}/${RELEASE_ID}"

                        echo "======================================"
                        echo "        INICIANDO DEPLOY"
                        echo "======================================"

                        echo ""
                        echo "Release: $RELEASE_ID"

                        # --------------------------------------------------
                        # 1. Testar SSH
                        # --------------------------------------------------

                        echo ""
                        echo "1. Testando conexão SSH..."

                        ssh $SSH_OPTS "$SERVER" \
                            "echo 'Conexão SSH estabelecida!'"

                        # --------------------------------------------------
                        # 2. Criar release
                        # --------------------------------------------------

                        echo ""
                        echo "2. Criando diretório da release..."

                        ssh $SSH_OPTS "$SERVER" "
                            set -eu

                            mkdir -p '$RELEASE_DIR'
                        "

                        # --------------------------------------------------
                        # 3. Copiar aplicação
                        # --------------------------------------------------

                        echo ""
                        echo "3. Enviando aplicação..."

                        scp $SSH_OPTS -r app/. \
                            "$SERVER:$RELEASE_DIR/"

                        # --------------------------------------------------
                        # 4. Instalar dependências
                        # --------------------------------------------------

                        echo ""
                        echo "4. Instalando dependências de produção..."

                        ssh $SSH_OPTS "$SERVER" "
                            set -eu

                            cd '$RELEASE_DIR'

                            npm ci --omit=dev
                        "

                        # --------------------------------------------------
                        # 5. Validar release
                        # --------------------------------------------------

                        echo ""
                        echo "5. Validando release..."

                        ssh $SSH_OPTS "$SERVER" "
                            set -eu

                            cd '$RELEASE_DIR'

                            test -f package.json
                            test -f server.js
                            test -d node_modules

                            echo 'Release validada com sucesso.'
                        "

                        # --------------------------------------------------
                        # 6. Parar aplicação antiga
                        # --------------------------------------------------

                        echo ""
                        echo "6. Parando aplicação anterior..."

                        ssh $SSH_OPTS "$SERVER" '
                            set -eu

                            PID=$(sudo lsof -t -i :3000 2>/dev/null || true)

                            if [ -n "$PID" ]; then

                                echo "Processo encontrado: $PID"
                                echo "Enviando SIGTERM..."

                                sudo kill -TERM "$PID" || true

                                for i in $(seq 1 10); do

                                    if ! sudo kill -0 "$PID" 2>/dev/null; then
                                        echo "Processo encerrado."
                                        break
                                    fi

                                    echo "Aguardando processo terminar..."
                                    sleep 1

                                done

                                if sudo kill -0 "$PID" 2>/dev/null; then
                                    echo "Processo não encerrou."
                                    echo "Enviando SIGKILL..."

                                    sudo kill -KILL "$PID" || true
                                    sleep 1
                                fi

                            else

                                echo "Nenhuma aplicação rodando na porta 3000."

                            fi
                        '

                        # --------------------------------------------------
                        # 7. Fazer backup da versão atual
                        # --------------------------------------------------

                        echo ""
                        echo "7. Preservando versão atual..."

                        ssh $SSH_OPTS "$SERVER" "
                            set -eu

                            if [ -d '$REMOTE_DIR' ]; then

                                rm -rf '$REMOTE_DIR.backup'

                                mv '$REMOTE_DIR' '$REMOTE_DIR.backup'

                            fi
                        "

                        # --------------------------------------------------
                        # 8. Instalar nova versão
                        # --------------------------------------------------

                        echo ""
                        echo "8. Instalando nova versão..."

                        ssh $SSH_OPTS "$SERVER" "
                            set -eu

                            mv '$RELEASE_DIR' '$REMOTE_DIR'
                        "

                        # --------------------------------------------------
                        # 9. Iniciar aplicação
                        # --------------------------------------------------

                        echo ""
                        echo "9. Iniciando aplicação..."

                        ssh $SSH_OPTS "$SERVER" "
                            set -eu

                            cd '$REMOTE_DIR'

                            nohup npm start > app.log 2>&1 < /dev/null &
                        "

                        # --------------------------------------------------
                        # 10. Health check
                        # --------------------------------------------------

                        echo ""
                        echo "10. Aguardando aplicação..."

                        SUCCESS=false

                        for i in \$(seq 1 15); do

                            echo "Health check: tentativa \$i/15"

                            if ssh $SSH_OPTS "$SERVER" \
                                "curl -fs http://localhost:$APP_PORT/status > /dev/null"
                            then

                                SUCCESS=true
                                echo "Aplicação respondeu com sucesso."
                                break

                            fi

                            sleep 2

                        done

                        # --------------------------------------------------
                        # 11. Rollback se necessário
                        # --------------------------------------------------

                        if [ "$SUCCESS" != "true" ]; then

                            echo ""
                            echo "======================================"
                            echo "      DEPLOY FALHOU"
                            echo "======================================"

                            echo ""
                            echo "Logs da nova aplicação:"

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

                            echo ""
                            echo "Executando rollback..."

                            ssh $SSH_OPTS "$SERVER" '
                                set -eu

                                PID=$(sudo lsof -t -i :3000 2>/dev/null || true)

                                if [ -n "$PID" ]; then
                                    sudo kill -TERM "$PID" || true
                                    sleep 2
                                fi
                            '

                            ssh $SSH_OPTS "$SERVER" "
                                set -eu

                                rm -rf '$REMOTE_DIR'

                                if [ -d '$REMOTE_DIR.backup' ]; then
                                    mv '$REMOTE_DIR.backup' '$REMOTE_DIR'
                                fi
                            "

                            echo ""
                            echo "Rollback concluído."

                            exit 1
                        fi

                        # --------------------------------------------------
                        # 12. Limpeza
                        # --------------------------------------------------

                        echo ""
                        echo "11. Limpando backup..."

                        ssh $SSH_OPTS "$SERVER" "
                            rm -rf '$REMOTE_DIR.backup'
                        "

                        echo ""
                        echo "12. Validando processo..."

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
        }

        always {
            echo "Pipeline finalizada."
        }
    }
}
