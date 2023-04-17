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


### GitLab CI/CD  

- Cоздает Docker-образ приложения, используя Dockerfile, который расположен в репозитории.  
- Этап "test" выполняет тестирование приложения, используя NPM.  
- Этап "package" упаковывает Docker-образ в TAR-архив.  
- Наконец, этап "deploy" доставляет TAR-архив на удаленный сервер и запускает Docker-контейнер приложения.  
```yml
stages:
  - build
  - test
  - package
  - deploy

variables:
  APP_NAME: myapp
  DOCKER_IMAGE_NAME: myapp/docker-image

build:
  stage: build
  image: docker:latest
  script:
    - docker build -t $DOCKER_IMAGE_NAME:$CI_COMMIT_SHA .

test:
  stage: test
  image: node:latest
  script:
    - npm install
    - npm run test

package:
  stage: package
  image: docker:latest
  script:
    - docker tag $DOCKER_IMAGE_NAME:$CI_COMMIT_SHA $DOCKER_IMAGE_NAME:latest
    - docker save -o $APP_NAME.tar $DOCKER_IMAGE_NAME:latest

deploy:
  stage: deploy
  image: docker:latest
  script:
    - ssh user@server "mkdir -p /opt/$APP_NAME"
    - scp $APP_NAME.tar user@server:/opt/$APP_NAME/
    - ssh user@server "docker load -i /opt/$APP_NAME/$APP_NAME.tar"
    - ssh user@server "docker stop $APP_NAME || true"
    - ssh user@server "docker rm $APP_NAME || true"
    - ssh user@server "docker run -d --name $APP_NAME -p 80:80 $DOCKER_IMAGE_NAME:latest"
```

### Gitlab CI/CD  
- Cоздаётся Docker-образ приложения и сохраняется в Docker hub  
- Затем создаётся Docker-образ, используемый для запуска юниттестов  
- На этапе тестирования запускаются тесты  
- На этапе развертывания приложение разворачивается в Kubernetes-кластере  
```yml
stages:
  - build
  - test
  - deploy

variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: ""

.build-image:
  image: docker:latest
  services:
    - docker:dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker build -t $CI_REGISTRY_IMAGE/app .
    - docker push $CI_REGISTRY_IMAGE/app

.build-artifacts:
  stage: build
  extends: .build-image
  script:
    - npm install
    - npm run build
    - mv build artifacts/

.test-image:
  image: docker:latest
  services:
    - docker:dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker build -t $CI_REGISTRY_IMAGE/test .
    - docker push $CI_REGISTRY_IMAGE/test

.test-unit:
  stage: test
  extends: .test-image
  script:
    - npm install
    - npm run test:unit

.test-e2e:
  stage: test
  extends: .test-image
  script:
    - npm install
    - npm run test:e2e

.deploy-image:
  image: docker:latest
  services:
    - docker:dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker build -t $CI_REGISTRY_IMAGE/app:$CI_COMMIT_REF_NAME .
    - docker push $CI_REGISTRY_IMAGE/app:$CI_COMMIT_REF_NAME
    - kubectl config set-context $KUBE_CONTEXT
    - kubectl config use-context $KUBE_CONTEXT
    - kubectl apply -f kubernetes/deployment.yaml

.deploy:
  stage: deploy
  environment:
    name: production
  script:
    - kubectl config set-context $KUBE_CONTEXT
    - kubectl config use-context $KUBE_CONTEXT
    - kubectl apply -f kubernetes/service.yaml

```



Добавить тимсити
