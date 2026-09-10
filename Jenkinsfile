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