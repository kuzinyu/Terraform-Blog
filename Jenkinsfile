pipeline {
    agent{node 'minir'}

    stages {
        stage('Checkout') {
            steps {
            checkout([$class: 'GitSCM', branches: [[name: '*/main']], extensions: [], userRemoteConfigs: [[url: 'https://github.com/vitaly-zverev/Terraform-Blog.git']]])            

          }
        }
        
        stage ("terraform init") {
            steps {
                sh ('/opt/homebrew/bin/terraform providers lock -net-mirror=https://terraform-mirror.yandexcloud.net -platform=linux_amd64 -platform=darwin_arm64 yandex-cloud/yandex')
                sh ('/opt/homebrew/bin/terraform init') 
            }
        }
        
        stage ("terraform plan") {
            steps {
                echo "Terraform plan"
                sh ('''
                     set | grep TF_VAR
                     /opt/homebrew/bin/terraform plan -no-color -out plan
                     
                     #cat plan
                  '''
                  ) 
           }
        }
        
        stage ("terraform apply ") {
            steps {
                echo "Terraform apply"
                sh ('''
                     set | grep TF_VAR
                     /opt/homebrew/bin/terraform apply -input=false -auto-approve -no-color "plan" 
                     
                     #cat plan
                  '''
                  ) 
           }
        }
        
        
    }
}