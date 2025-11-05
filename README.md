# 🚀 DevOps Pipeline con Herramientas Gratuitas

Este proyecto implementa un pipeline DevOps **completo y funcional** usando solo herramientas **gratuitas**, siguiendo la guía de FreeCodeCamp *“How to Build a Production-Ready DevOps Pipeline with Free Tools”*.

---

## 🧩 Estructura del Proyecto

devops-practica/
├── backend/
│ ├── Dockerfile
│ ├── index.js
│ ├── package.json
│ └── package-lock.json
├── k8s/
│ ├── deployment.yaml
│ └── service.yaml
├── infra/
│ └── main.tf
├── .github/
│ └── workflows/
│ └── ci.yml
└── README.md



---

## ⚙️ Tecnologías Utilizadas

| Componente | Herramienta |
|-------------|-------------|
| **Control de versiones** | Git + GitHub |
| **Backend** | Node.js + Express |
| **Contenedores** | Docker |
| **CI/CD** | GitHub Actions |
| **Infraestructura como código** | Terraform |
| **Orquestación** | Kubernetes (K3d) |
| **Seguridad** | GitHub CodeQL |
| **Monitoreo** | Grafana Cloud / Prometheus (propuestos) |

---

## 🧱 Backend CRUD

El backend expone los endpoints `/users` (GET/POST) y `/healthz`.  
Construido con **Express + PostgreSQL**, con contenedor Docker optimizado en dos etapas (multi-stage build).

---

## 🔄 Integración Continua (CI)

El flujo `ci.yml` en `.github/workflows` ejecuta automáticamente:

1. `actions/checkout` → clona el repo  
2. `actions/setup-node` → configura Node 18  
3. `actions/cache` → usa cache de dependencias npm  
4. `npm ci` → instala dependencias  
5. `npm test` y `npm run lint` → validaciones básicas  
6. Construcción Docker con **BuildKit**

Todo se ejecuta automáticamente en GitHub Actions.

---

## 🐳 Dockerfile

Multi-stage build basado en `node:18-alpine`:
- Etapa **builder**: instala dependencias y compila
- Etapa **final**: imagen liviana solo con dependencias de producción

```bash
docker build -t crud-backend:optimized .
docker run -p 3000:3000 crud-backend:optimized

☸️ Kubernetes

Deployment y Service declarativos en /k8s/ con:

Réplicas: 2

Liveness y readiness probes (/healthz)

Límites de recursos (128 Mi / 100m CPU)

kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

🏗️ Terraform

Archivo infra/main.tf define infraestructura declarativa:

Servicio web en Render (free tier)

Repositorio GitHub como fuente de despliegue

Variables seguras para API keys

terraform init
terraform plan -out=infra.tfplan
terraform apply infra.tfplan

🛡️ Seguridad

CodeQL: análisis de seguridad automatizado en GitHub Actions.

Trivy / OWASP ZAP (opcionales): escaneo de vulnerabilidades en contenedores y APIs.

📊 Resultado

✅ Pipeline automatizado que cubre:

Construcción y validación del código

Seguridad por análisis estático

Contenerización optimizada

Infraestructura declarativa

Orquestación y despliegue reproducible