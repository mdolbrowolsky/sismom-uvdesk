pipeline {
    agent any

    environment {
        //Variáveis obrigatórias
        DOCKER_REGISTRY = "registry.coids.inpe.br"
        REPOSITORY = "sismon"
        IMAGE_NAME = "uvdesk"
        IMAGE_TAG = "${BUILD_NUMBER}"

	//Variáveis não obrigatórias
        JSON_OUTPUT = "version.json"        
    }

    stages {
        stage('Pre-Build') {
            steps {
                script {
                    echo "Generating $JSON_OUTPUT..."

                    // Obter a hora atual no formato ISO 8601 (UTC)
                    def buildTimestamp = new Date().format("yyyy-MM-dd'T'HH:mm:ss'Z'", TimeZone.getTimeZone('UTC'))

                    // Gerar o JSON com detalhes da imagem
                    def jsonContent = """{
                        "repository": "${REPOSITORY}",
                        "image_name": "${IMAGE_NAME}",
                        "image_tag": "${IMAGE_TAG}",
                        "generated_at": "${buildTimestamp}"
                    }"""

                    // Salvar o JSON em um arquivo
                    writeFile file: "src/${JSON_OUTPUT}", text: jsonContent

                    echo "$JSON_OUTPUT generated successfully:"
                    sh "cat src/${JSON_OUTPUT}"
                }
            }
        }        
        
        stage('Build Docker Image') {
            steps {
                script {
                    try {
                        sh 'docker build -t $DOCKER_REGISTRY/$REPOSITORY/$IMAGE_NAME:$IMAGE_TAG -t $DOCKER_REGISTRY/$REPOSITORY/$IMAGE_NAME:latest .'
                    } catch (Exception e) {
                        currentBuild.result = 'FAILURE'
                        throw e
                    }
                }
            }
        }

        stage('Push Image to Registry') {
            steps {
                script {
                    try {
                        sh 'docker push $DOCKER_REGISTRY/$REPOSITORY/$IMAGE_NAME:$IMAGE_TAG'
                        sh 'docker push $DOCKER_REGISTRY/$REPOSITORY/$IMAGE_NAME:latest'
                    } catch (Exception e) {
                        currentBuild.result = 'FAILURE'
                        throw e
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    try {
                        echo "Deploying image $DOCKER_REGISTRY/$REPOSITORY/$IMAGE_NAME:$IMAGE_TAG to live"

                        sh 'deploy ${REPOSITORY} ${IMAGE_NAME} ${IMAGE_TAG}'
                    } catch (Exception e) {
                        currentBuild.result = 'FAILURE'
                        throw e
                    }
                }
            }
        }        
    }

    post {
        always {
            // Garantir que a limpeza de imagens será sempre executada no final
            echo "Cleaning up Docker resources..."

            // Remover containers parados, volumes não usados, redes não usadas e imagens não referenciadas
            sh 'docker system prune -af --volumes'
        }
        
        success {
            echo 'Imagem Docker foi enviada com sucesso!'
        }
        
        failure {
            echo 'Falha ao construir ou enviar a imagem Docker.'
        }
    }
}
