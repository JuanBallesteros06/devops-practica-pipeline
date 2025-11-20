#!/bin/bash
set -e

echo "⚠️  Iniciando Rollback de Canary..."

NAMESPACE="production"

# Paso 1: Restaurar VirtualService para enviar 100% del tráfico a v1
echo "🔄 Restaurando tráfico al 100% en v1 (versión estable)..."
kubectl apply -n $NAMESPACE -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: crud-backend-virtualservice
spec:
  hosts:
    - crud.example
  http:
    - name: primary
      route:
        - destination:
            host: crud-backend-service
            subset: v1
          weight: 100
        - destination:
            host: crud-backend-service
            subset: v2
          weight: 0
EOF

# Paso 2: Escalar v2 a 0 réplicas (opcional, para ahorrar recursos)
echo "📉 Escalando deployment v2 a 0 réplicas..."
kubectl scale deployment/crud-backend-v2 --replicas=0 -n $NAMESPACE

echo ""
echo "✅ Rollback completado exitosamente"
echo "📊 Estado actual:"
kubectl get deployments -n $NAMESPACE -l app=crud-backend
echo ""
echo "🛡️  Sistema restaurado a versión estable (v1 - 100% tráfico)"