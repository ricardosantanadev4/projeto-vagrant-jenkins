pipeline {

    agent any

    environment {
        SERVER = "vagrant@192.168.56.20"
        REMOTE_DIR = "/home/vagrant/app"
        RELEASES_DIR = "/home/vagrant/releases"
        APP_PORT = "3000"
        HEALTH_URL = "http://localhost:3000/status"
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

        stage("Package") {
            steps {
                echo "Empacotando aplicação"

                sh '''
                    set -eu

                    echo "Criando artefato..."

                    rm -f application.tar.gz

                    tar \
                        --exclude='app/node_modules' \
                        --exclude='app/.git' \
                        -czf application.tar.gz \
                        app/

                    echo "Artefato criado:"
                    ls -lh application.tar.gz
                '''
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
                        HEALTH_URL="${HEALTH_URL}"

                        RELEASE_ID=$(date +%Y%m%d-%H%M%S)-$$
                        RELEASE_DIR="${RELEASES_DIR}/${RELEASE_ID}"

                        echo "======================================"
                        echo "        INICIANDO DEPLOY"
                        echo "======================================"

                        echo ""
                        echo "Release: $RELEASE_ID"

                        # ==================================================
                        # 1. SSH
                        # ==================================================

                        echo ""
                        echo "1. Testando conexão SSH..."

                        ssh $SSH_OPTS "$SERVER" \
                            "echo 'Conexão SSH estabelecida!'"

                        # ==================================================
                        # 2. Preparar diretório remoto
                        # ==================================================

                        echo ""
                        echo "2. Preparando diretório remoto..."

                        ssh $SSH_OPTS "$SERVER" "
                            set -eu

                            mkdir -p '$RELEASE_DIR'
                        "

                        # ==================================================
                        # 3. Enviar artefato
                        # ==================================================

                        echo ""
                        echo "3. Enviando artefato..."

                        scp $SSH_OPTS \
                            application.tar.gz \
                            "$SERVER:$RELEASE_DIR/"

                        # ==================================================
                        # 4. Extrair artefato
                        # ==================================================

                        echo ""
                        echo "4. Extraindo aplicação..."

                        ssh $SSH_OPTS "$SERVER" "
                            set -eu

                            cd '$RELEASE_DIR'

                            tar -xzf application.tar.gz

                            rm -f application.tar.gz
                        "

                        # ==================================================
                        # 5. Ajustar estrutura
                        # ==================================================

                        echo ""
                        echo "5. Preparando estrutura da release..."

                        ssh $SSH_OPTS "$SERVER" "
                            set -eu

                            if [ -d '$RELEASE_DIR/app' ]; then

                                cp -a '$RELEASE_DIR/app'/.' '$RELEASE_DIR'/ 
                                rm -rf '$RELEASE_DIR/app'

                            fi
                        "

                        # ==================================================
                        # 6. Instalar dependências de produção
                        # ==================================================

                        echo ""
                        echo "6. Instalando dependências de produção..."

                        ssh $SSH_OPTS "$SERVER" "
                            set -eu

                            cd '$RELEASE_DIR'

                            npm ci --omit=dev
                        "

                        # ==================================================
                        # 7. Validar release
                        # ==================================================

                        echo ""
                        echo "7. Validando release..."

                        ssh $SSH_OPTS "$SERVER" "
                            set -eu

                            cd '$RELEASE_DIR'

                            test -f package.json
                            test -f server.js
                            test -d node_modules

                            echo 'Arquivos principais encontrados.'
                            echo 'Release validada.'
                        "

                        # ==================================================
                        # 8. Verificar aplicação atual
                        # ==================================================

                        echo ""
                        echo "8. Verificando aplicação atual..."

                        OLD_PID=$(ssh $SSH_OPTS "$SERVER" \
                            "sudo lsof -t -i :$APP_PORT 2>/dev/null || true")

                        if [ -n "$OLD_PID" ]; then
                            echo "Aplicação atual encontrada. PID: $OLD_PID"
                        else
                            echo "Nenhuma aplicação atual encontrada."
                        fi

                        # ==================================================
                        # 9. Parar aplicação
                        # ==================================================

                        echo ""
                        echo "9. Parando aplicação anterior..."

                        ssh $SSH_OPTS "$SERVER" '
                            set -eu

                            PID=$(sudo lsof -t -i :3000 2>/dev/null || true)

                            if [ -n "$PID" ]; then

                                echo "Parando PID: $PID"

                                sudo kill -TERM "$PID" || true

                                for i in $(seq 1 10); do

                                    if ! sudo kill -0 "$PID" 2>/dev/null; then
                                        echo "Processo encerrado."
                                        break
                                    fi

                                    echo "Aguardando encerramento..."
                                    sleep 1

                                done

                                if sudo kill -0 "$PID" 2>/dev/null; then

                                    echo "Processo não encerrou."

                                    sudo kill -KILL "$PID" || true

                                    sleep 1
                                fi

                            else

                                echo "Nenhum processo na porta 3000."

                            fi
                        '

                        # ==================================================
                        # 10. Backup da versão atual
                        # ==================================================

                        echo ""
                        echo "10. Criando backup..."

                        ssh $SSH_OPTS "$SERVER" "
                            set -eu

                            rm -rf '${REMOTE_DIR}.backup'

                            if [ -d '$REMOTE_DIR' ]; then
                                mv '$REMOTE_DIR' '${REMOTE_DIR}.backup'
                            fi
                        "

                        # ==================================================
                        # 11. Ativar nova release
                        # ==================================================

                        echo ""
                        echo "11. Ativando nova release..."

                        ssh $SSH_OPTS "$SERVER" "
                            set -eu

                            mv '$RELEASE_DIR' '$REMOTE_DIR'
                        "

                        # ==================================================
                        # 12. Iniciar aplicação
                        # ==================================================

                        echo ""
                        echo "12. Iniciando aplicação..."

                        ssh $SSH_OPTS "$SERVER" "
                            set -eu

                            cd '$REMOTE_DIR'

                            nohup npm start > app.log 2>&1 < /dev/null &
                        "

                        # ==================================================
                        # 13. Health check
                        # ==================================================

                        echo ""
                        echo "13. Executando health check..."

                        DEPLOY_OK=false

                        for i in \$(seq 1 15); do

                            echo "Tentativa \$i/15..."

                            if ssh $SSH_OPTS "$SERVER" \
                                "curl -fs '$HEALTH_URL' > /dev/null"
                            then

                                echo "Health check OK."

                                DEPLOY_OK=true

                                break
                            fi

                            sleep 2

                        done

                        # ==================================================
                        # 14. Rollback
                        # ==================================================

                        if [ "$DEPLOY_OK" != "true" ]; then

                            echo ""
                            echo "======================================"
                            echo "         DEPLOY FALHOU"
                            echo "======================================"

                            echo ""
                            echo "Logs da aplicação:"

                            ssh $SSH_OPTS "$SERVER" \
                                "tail -n 100 '$REMOTE_DIR/app.log' || true"

                            echo ""
                            echo "Processos Node:"

                            ssh $SSH_OPTS "$SERVER" \
                                "ps aux | grep '[n]ode' || true"

                            echo ""
                            echo "Porta $APP_PORT:"

                            ssh $SSH_OPTS "$SERVER" \
                                "sudo lsof -i :$APP_PORT || true"

                            echo ""
                            echo "Executando rollback..."

                            ssh $SSH_OPTS "$SERVER" '
                                PID=$(sudo lsof -t -i :3000 2>/dev/null || true)

                                if [ -n "$PID" ]; then
                                    sudo kill -TERM "$PID" || true
                                    sleep 2
                                fi
                            '

                            ssh $SSH_OPTS "$SERVER" "
                                set -eu

                                rm -rf '$REMOTE_DIR'

                                if [ -d '${REMOTE_DIR}.backup' ]; then
                                    mv '${REMOTE_DIR}.backup' '$REMOTE_DIR'
                                fi
                            "

                            echo ""
                            echo "Rollback concluído."

                            exit 1
                        fi

                        # ==================================================
                        # 15. Remover backup
                        # ==================================================

                        echo ""
                        echo "14. Limpando backup..."

                        ssh $SSH_OPTS "$SERVER" "
                            rm -rf '${REMOTE_DIR}.backup'
                        "

                        # ==================================================
                        # 16. Validação final
                        # ==================================================

                        echo ""
                        echo "15. Validação final..."

                        ssh $SSH_OPTS "$SERVER" "
                            sudo lsof -i :$APP_PORT
                        "

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
