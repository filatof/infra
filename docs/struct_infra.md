## Структура проекта
```bash
infra/
├── ansible/
│   ├── playbooks/ #  папка с плейбуками проекта
│   │   ├── monitoring.yml 
│   │   └── playbook.yml
│   ├── requirements/ 
│   │   └── requirements.yml
│   ├── roles/
│   │   ├── alertmanager/
│   │   │   ├── files/
│   │   │   │   └── alertmanager.yml
│   │   │   └── tasks/
│   │   │       └── main.yml
│   │   ├── default_exporters/
│   │   │   └── tasks/
│   │   │       └── main.yml
│   │   ├── docker/
│   │   │   └── tasks/
│   │   │       └── main.yml
│   │   ├── gitlab/
│   │   │   ├── defaults/
│   │   │   │   └── main.yml
│   │   │   ├── tasks/
│   │   │   │   └── main.yml
│   │   │   └── templates/
│   │   │       └── gitlab.rb.j2
│   │   ├── gitlab-runner/
│   │   │   ├── defaults/
│   │   │   │   └── main.yml
│   │   │   └── tasks/
│   │   │       └── main.yml
│   │   ├── grafana/
│   │   │   └── tasks/
│   │   │       └── main.yml
│   │   ├── prometheus/
│   │   │   ├── tasks/
│   │   │   │   └── main.yml
│   │   │   └── templates/
│   │   │       └── prometheus.yml.j2
│   ├── ansible.cfg
│   ├── docker-compose.yml
│   └── hosts
├── docs/
│   ├── ladr.md
│   └── struct_infra.md
├── terraform/
│   ├── example_user_data.yml
│   ├── main.tf
│   └─── sbermain.tf.bak
├── .gitignore
├── ladr.md
└── README.md
```
