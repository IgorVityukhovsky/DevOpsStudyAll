## 01-intro  

**Jira**  
**Agile** - гибкая методология, точнее семейство. Входят kanban и scrum  
**Scrum** - планирование и спринты  
**Kanban** - поток задач на доске  

**Waterfall** (водопадная или каскадная модель) — это рабочий процесс когда мы сначала планируем что будет сделано, а потом делаем. «Водопадным» подход называется потому что каждый этап последовательно следует за следующим.  
**Agile** (гибкая методология) — это когда мы не пытаемся заглядывать далеко вперед, а двигаемся итеративно (циклами) и инкрементально (имея промежуточные результаты). За счет такого подхода мы можем быстрее и чаще получать обратную связь, и корректировать движение.  


## 02-cicd  

**SonarQube**  
Платформа для непрерывного анализа и измерения качества кода. Анализирует баги, синтаксические ошибки, выводит предупреждения  

**Nexus**  
Менеджер репозиториев и артефактов, например докера и других.  
Используется для локального хранения важных данных, а так же как проксирующий сервер для локальной сети

**Maven**  
Сборщик Java приложений  

## 03-Jenkins  

Jenkinsfile  
Freestyle Job  
ScriptedJenkinsfile  


### Jenkinsfile  
Пайплайн берёт ансибл плейбук с репозитория и раскатывает его на облачные машины  

```yml
pipeline {
    agent any

    stages {
        stage('Git') {
            steps {
                sh 'git clone https://github.com/IgorVityukhovsky/example-playbook.git && cd example-playbook && ansible-playbook site.yml -e "ansible_become_password=123"'
            }
        }
        
    }
}
```

### Jenkinsfile
Скачивает репозиторий из Git  
Собирает Docker-образ с помощью Dockerfile  
Запускает контейнер Docker, который использует собранный образ  
Устанавливает зависимости Python, указанные в requirements.txt  
Выполняет тесты Python с помощью Pytest  
```
pipeline {
    agent any
    stages {
        stage('Clone repository') {
            steps {
                git branch: 'main', url: 'https://github.com/user/repo.git'
            }
        }
        stage('Build Docker image') {
            steps {
                sh 'docker build -t my-image:${BUILD_NUMBER} -f Dockerfile .'
            }
        }
        stage('Run Docker container') {
            steps {
                sh 'docker run -d -p 8000:8000 --name my-container my-image:${BUILD_NUMBER}'
            }
        }
        stage('Install Python dependencies') {
            steps {
                sh 'pip install -r requirements.txt'
            }
        }
        stage('Run tests') {
            steps {
                sh 'pytest'
            }
        }
    }
    post {
        always {
            sh 'docker stop my-container && docker rm my-container'
        }
    }
}
```
### Jenkinsfile  
Скачивает репозиторий с GitHub.  
Запускает Terraform для создания виртуальной машины.  
Копирует файлы из репозитория на созданную виртуальную машину.  
Рестартует на удаленной машине Nginx.  
```
pipeline {
    agent any
    environment {
        // Устанавливаем переменные окружения
        VM_IP = '123.45.67.89'
        VM_USER = 'ubuntu'
    }
    stages {
        stage('Clone Repository') {
            steps {
                // Клонируем репозиторий из GitHub
                git 'https://github.com/user/repo.git'
            }
        }

        stage('Terraform Apply') {
            steps {
                // Устанавливаем Terraform и запускаем манифест
                sh '''
                    wget https://releases.hashicorp.com/terraform/1.0.9/terraform_1.0.9_linux_amd64.zip
                    unzip terraform_1.0.9_linux_amd64.zip
                    sudo mv terraform /usr/local/bin/
                    cd terraform
                    terraform init
                    terraform apply -auto-approve
                '''
            }
        }

        stage('Copy files to VM') {
            steps {
                // Копируем файлы на виртуальную машину
                sh '''
                    ssh-keyscan -H ${VM_IP} >> ~/.ssh/known_hosts
                    scp -i ~/.ssh/id_rsa -r ./path/to/files ${VM_USER}@${VM_IP}:/home/${VM_USER}/
                '''
            }
        }

        stage('Restart Nginx') {
            steps {
                // Рестартуем Nginx на виртуальной машине
                sh '''
                    ssh -i ~/.ssh/id_rsa ${VM_USER}@${VM_IP} 'sudo systemctl restart nginx'
                '''
            }
        }
    }
}
```




## 05-GitLab  

Побыть участником всего процесса  

**DevOps**  
Написать докерфайл по определённым требованиям  

**Product Owner**  
Создать Issue с необходимыми правками  

**Developer**  
Взять в работу, создать отдельную ветку, сделать изменения, подготовить Merge Requst, влить необходимые изменения в master  

**Tester**  
Протестировать изменения в контейнере  


Добавить тимсити
