#!/bin/bash
set -e

echo "🚀 Promoviendo Canary a Producción..."

NAMESPACE="production"
IMAGE="${IMAGE:-ghcr.io/$GITHUB_REPOSITORY/app:$GITHUB_SHA}"

echo "📦 Imagen a promover: $IMAGE"

# Paso 1: Actualizar v1 con la nueva imagen (la que está en v2)
echo "⬆️  Actualizando deployment v1 con la nueva imagen..."
kubectl set image deployment/crud-backend-v1 \
  crud-backend=$IMAGE \
  -n $NAMESPACE

kubectl rollout status deployment/crud-backend-v1 \
  -n $NAMESPACE \
  --timeout=3m

# Paso 2: Cambiar el VirtualService para enviar 100% del tráfico a v1
echo "🔄 Redirigiendo 100% del tráfico a v1..."
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

echo ""
echo "✅ Promoción completada exitosamente"
echo "📊 Estado actual:"
kubectl get deployments -n $NAMESPACE -l app=crud-backend
echo ""
echo "🎉 v2 ha sido promovido a v1. Tráfico: 100% a v1"