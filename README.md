# Инструкция по развертыванию инфраструктуры

Этот репозиторий содержит код Terraform для развертывания инфраструктуры состоящей из балансировщика, сервера для тестов test.infrastruct.ru и собственного gitlab сервера gitlab.infrastruct.ru. В директории ansible находится код для развертывания gitlab сервера и тестового окружения.

[Документация по архитектурным решениям](docs/ladr.md)
[Структура папок и файлов проекта](docs/struct_infra.md)

## Содержание

- [Требования](#требования)
- [Установка Terraform](#установка-terraform)
- [Установка Ansible](#установка-ansible)
- [Установка зависимостей для Ansible](#установка-зависимостей-для-ansible)
- [Развертывание инфраструктуры](#развертывание-инфраструктуры)
- [Настройка сервера](#настройка-сервера)
- [Установка мониторинга](#установка-мониторинга)
- [Заключение](#заключение)

## Требования

Для выполнения данной инструкции вам потребуются следующие инструменты:

- [Terraform](https://www.terraform.io/downloads.html)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
- Доступ к облачному провайдеру Yandex cloud

## Установка Terraform

1. Скачайте и установите Terraform с официального сайта: [Terraform Downloads](https://www.terraform.io/downloads.html)
2. Проверьте установку, выполнив команду:
    ```sh
    terraform --version
    ```

## Установка Ansible

1. Установите Ansible, следуя инструкциям на официальном сайте: [Ansible Installation Guide](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
2. Проверьте установку, выполнив команду:
    ```sh
    ansible --version
    ```

## Установка зависимостей для Ansible

1. Установите необходимые коллекции Ansible, выполнив команду:
    ```sh
    ansible-galaxy collection install -r requirements.yml
    ```

## Развертывание инфраструктуры

1. Клонируйте репозиторий:
    ```sh
    git clone https://github.com/filatof/infra.git
    cd infra
    ```

2. Инициализируйте Terraform:
    ```sh
    terraform init
    ```

3. Примените конфигурацию Terraform:
    ```sh
    terraform apply
    ```

4. Подтвердите выполнение команды, введя `yes` при появлении запроса.

## Настройка сервера

1. После успешного развертывания инфраструктуры, выполните команду для получения IP-адреса сервера и добавьте их в файл hosts:
    ```sh
    terraform output instance_ips # ip тестового сервера, будет доступен test.infrastruct.ru
    terraform output instance_gitlab_ips # ip сервера gitlab, будет доступен gitlab.unfrastruct.ru
    terraform output web_loadbalancer_ip # ip балансировщика проекта, будет доступен infrastaruct.ru
    terraform output instance_prometheus_ip # ip prjmetheus и grafana
    ```

2. Настройте Ansible для выполнения плейбука:
    ```sh
    ansible-playbook  playbooks/playbook.yml
    ```
## Playbook состоит из ролей:  
- docker - установит докер и все зависимости  
- gitlab - скачает и установит сервер gitlab. Ключ для root находится в /srv/gitlab/config/initial_root_password  
- gitlab-runner - установит runner. Регистрировать нужно руками, иструкция здесь https://docs.gitlab.com/runner/register/index.html  

После настройки тестовой среды нужно создать пустой проект в вашем gitlab. Скачайте репозиторий https://gitlab.com/filatof/service.git , он содержит файлы пайплайна и диплоя проекта на тестовый сервер, и привяжите к вашему новому проекту на вашем собственном сервере gitlab. Далее нужно замержить проект https://github.com/bhavenger/skillbox-diploma.git в ваш новый проект. Для этого зайдите в директорию с проектом и выполните команды:
   ```sh
   git remote add skillbox-diploma https://github.com/bhavenger/skillbox-diploma.git
   git fetch skillbox-diploma
   git merge skillbox-diploma/main
   ```
После успешного слияния зафиксируйте изменения и отправьте их в ваш собственный удаленный репозиторий:  
   ```sh
   git add .
   git commit -m "Merged skillbox-diploma project into my service project"
   git push origin main
   ```
## Установка мониторинга

Запустите плейбук monitoring.yml 
   ```sh
   ansible-playbook playbooks/monitoring.yml
   ```
Данный плейбук установит prometheus, grafana, alertmanager и на все инстаный node_exporter

Переправте файл example_user_data.yml под себя. При инициализации инстанса prometheus, тераформ установит nginx и настроит обратный прокси на два домена promehteus и grafana

## Заключение

После выполнения всех шагов, ваша инфраструктура будет развернута, а на серверах будет установлен Docker, Gitlab и развернут мониторинг.
