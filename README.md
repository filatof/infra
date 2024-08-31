# Инструкция по развертыванию инфраструктуры

Этот репозиторий содержит код для развертывания инфраструктуры на Yandex Cloud с использованием Terraform и последующей настройки сервера с использованием Ansible. В инфраструктуру входит балансировщик нагрузки и один сервер с установленным Docker.

## Содержание

- [Требования](#требования)
- [Установка Terraform](#установка-terraform)
- [Установка Ansible](#установка-ansible)
- [Развертывание инфраструктуры](#развертывание-инфраструктуры)
- [Настройка сервера](#настройка-сервера)
- [Заключение](#заключение)

## Требования

Для выполнения данной инструкции вам потребуются следующие инструменты:

- [Terraform](https://www.terraform.io/downloads.html)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
- Доступ к облачному провайдеру Yandex Cloud

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

1. После успешного развертывания инфраструктуры, выполните команду для получения IP-адреса сервера и добавьте его в файл hosts:
    ```sh
    terraform output instance_ips
    ```

2. Настройте Ansible для выполнения плейбука:
    ```sh
    ansible-playbook -i inventory.ini playbook.yml
    ```

## Заключение

После выполнения всех шагов, ваша инфраструктура будет развернута, а на сервере будет установлен Docker и все необходимые зависимости.


