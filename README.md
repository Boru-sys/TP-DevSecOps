# TP DevSecOps - Pipeline GitOps Locale Sécurisée

##  Contexte

Ce projet a pour objectif de mettre en place une **pipeline GitOps complète en local**, permettant de déployer automatiquement une infrastructure de monitoring (Prometheus, Grafana, Jenkins) tout en intégrant des contrôles de sécurité à chaque étape.

---

##  Objectifs

* Implémenter une approche **GitOps**
* Automatiser le déploiement avec **Terraform**
* Configurer les services avec **Ansible**
* Mettre en place une pipeline CI/CD avec **Jenkins**
* Intégrer des outils de sécurité :

  * Checkov (IaC)
  * Trivy (containers)
* Déployer une stack de monitoring :

  * Prometheus
  * Grafana

---

##  Architecture

```text
                ┌──────────────────────────────┐
                │        GitHub (Repo)         │
                │   TP-DevSecOps (GitOps)      │
                └──────────────┬───────────────┘
                               │ Push (SSH)
                               ▼
                ┌──────────────────────────────┐
                │           Jenkins            │
                │        CI/CD Pipeline        │
                ├──────────────────────────────┤
                │ 1. Checkout Code             │
                │ 2. Scan IaC (Checkov)        │
                │ 3. Build Container           │
                │ 4. Scan Image (Trivy)        │
                │ 5. Deploy (Terraform)        │
                │ 6. Configure (Ansible)       │
                │ 7. Tests & Health Checks     │
                └──────────────┬───────────────┘
                               ▼
        ┌────────────────────────────────────────────┐
        │         Infrastructure Docker              │
        │                                            │
        │  ┌────────────┐  ┌────────────┐  ┌────────┐│
        │  │ Prometheus │  │  Grafana   │  │ Jenkins││
        │  └────────────┘  └────────────┘  └────────┘│
        └────────────────────────────────────────────┘
```

---

##  Structure du projet

```bash
tp-gitops-local/
├── infrastructure/terraform/   # Déploiement Docker
├── configuration/ansible/      # Configuration services
├── application/docker/         # Dockerfile app
├── monitoring/
│   ├── prometheus/
│   └── grafana/
├── security/policies/          # Policies Checkov
├── scripts/                    # Scripts sécurité & Jenkins
├── tests/                      # Tests Python
└── Jenkinsfile                 # Pipeline CI/CD
```

---

##  Fonctionnement du projet

###  GitOps Workflow

1. Le code est versionné dans GitHub
2. Un `git push` déclenche Jenkins
3. Jenkins exécute la pipeline :

   * Analyse sécurité (Checkov / Trivy)
   * Déploiement Terraform
   * Configuration Ansible
4. Les services sont déployés automatiquement

---

##  Sécurité intégrée

### Checkov

* Analyse Terraform / Ansible / Dockerfile
* Vérifie les bonnes pratiques sécurité

### Trivy

* Scan des images Docker
* Détection vulnérabilités HIGH / CRITICAL

---

## Déploiement

### 1. Terraform

```bash
cd infrastructure/terraform
terraform init
terraform apply -auto-approve
```

### 2. Ansible

```bash
cd configuration/ansible
ansible-playbook -i inventory.yml playbook.yml
```

---

## Tests

```bash
python3 tests/test_infrastructure.py
```

Vérifie :

* Containers actifs
* Services accessibles
* Prometheus collecte les métriques
* Grafana configuré

---

## Accès aux services

| Service    | URL                   |
| ---------- | --------------------- |
| Prometheus | http://localhost:9090 |
| Grafana    | http://localhost:3000 |
| Jenkins    | http://localhost:8080 |

👉 Grafana :

* user: `admin`
* password: `gitops2024`

---

## Validation

```bash
./scripts/validate-gitops.sh
```

---

## Accès Git (SSH)

Le projet utilise uniquement **SSH** :

```bash
git remote set-url origin git@github.com:<USER>/TP-DevSecOps.git
```

---

## Concepts clés

* GitOps
* Infrastructure as Code (IaC)
* CI/CD
* DevSecOps
* Monitoring
* Automatisation

---

## Résultat attendu

* Infrastructure déployée automatiquement
* Pipeline Jenkins fonctionnelle
* Aucun scan critique
* Monitoring opérationnel
* Tests validés 
