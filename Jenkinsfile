// Devemos aplicar os conceitos de Jenkins ao projeto em questão (app)

// Requisitos mínimos:
//    - Instalar dependências
//    - Build
//    - Teste
//    - post com sucess ou failure

pipeline {
    
    agent any

    stages {
        
        stage("Install"){
            steps{
                echo('Instalação de dependências')
                dir('app'){
                    sh "npm install"
                }
                echo(message: 'Etapa Finalizada')
            }
        }
        stage("Build"){
            steps{
                echo(message: 'Etapa de Build')
                dir('app'){
                    sh "npm run build"
                }
                echo(message: 'Etapa Finalizada')
            }
        }
        stage("Test"){
            steps{
                echo(message: 'Etapa de Testes')
                dir('app'){
                    sh "npm test"
                }
                echo(message: 'Etapa Finalizada')
            }
        }
        stage("Deploy") {
            steps {
                echo('Etapa de Deploy')

                sshagent(credentials: ['ssh_key']) {
                    sh '''
                        ssh -o StrictHostKeyChecking=no vagrant@192.168.56.20 \
                            "mkdir -p /home/vagrant/app"

                        tar --exclude=node_modules -czf - -C app . | \
                            ssh -o StrictHostKeyChecking=no vagrant@192.168.56.20 \
                            "tar -xzf - -C /home/vagrant/app"

                        ssh -o StrictHostKeyChecking=no vagrant@192.168.56.20 '
                            cd /home/vagrant/app &&
                            npm install --omit=dev &&
                            if [ -f app.pid ]; then
                                kill $(cat app.pid) 2>/dev/null || true
                            fi &&
                            nohup npm start > app.log 2>&1 &
                            echo $! > app.pid
                        '
                    '''
                }

                echo('Etapa Finalizada')
            }
        }
    }
    
    post {
        success {
            echo(message: 'The Stages were a Sucess!')
        }
        failure {
            echo(message: 'The process has failed!')
        }
    }
}