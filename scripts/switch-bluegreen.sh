#!/bin/bash
set -e

echo "🔄 Iniciando Switch de Blue a Green..."

BLUE_NAMESPACE="production"
GREEN_NAMESPACE="staging"
SERVICE_NAME="crud-backend-service"

echo "📊 Estado ANTES del switch:"
echo "════════════════════════════════════════════════════"
kubectl get svc $SERVICE_NAME -n $BLUE_NAMESPACE -o yaml | grep -A 3 "selector:"
echo ""

# Verificar que Green esté listo
echo "🔍 Verificando que Green esté completamente desplegado..."
GREEN_READY=$(kubectl get deployment crud-backend-v2 -n $GREEN_NAMESPACE -o jsonpath='{.status.readyReplicas}')
GREEN_DESIRED=$(kubectl get deployment crud-backend-v2 -n $GREEN_NAMESPACE -o jsonpath='{.spec.replicas}')

if [ "$GREEN_READY" != "$GREEN_DESIRED" ]; then
  echo "❌ Error: Green no está completamente listo"
  echo "   Réplicas deseadas: $GREEN_DESIRED"
  echo "   Réplicas listas: $GREEN_READY"
  exit 1
fi

echo "✅ Green está listo con $GREEN_READY/$GREEN_DESIRED réplicas"
echo ""

# Copiar los pods de Green a producción si no existen
echo "📦 Desplegando pods Green en namespace de producción..."
kubectl get deployment crud-backend-v2 -n $GREEN_NAMESPACE -o yaml | \
  sed "s/namespace: $GREEN_NAMESPACE/namespace: $BLUE_NAMESPACE/g" | \
  kubectl apply -f -

# Esperar a que los pods de Green en producción estén listos
echo "⏳ Esperando que los pods Green en producción estén listos..."
kubectl rollout status deployment/crud-backend-v2 -n $BLUE_NAMESPACE --timeout=3m

# Realizar el switch: cambiar selector del Service de v1 a v2
echo ""
echo "🔀 Cambiando selector del Service a version: v2 (Green)..."
kubectl patch service $SERVICE_NAME -n $BLUE_NAMESPACE -p '{"spec":{"selector":{"version":"v2"}}}'

echo ""
echo "⏳ Esperando 10 segundos para que el cambio se propague..."
sleep 10

# Verificar el cambio
echo ""
echo "📊 Estado DESPUÉS del switch:"
echo "════════════════════════════════════════════════════"
kubectl get svc $SERVICE_NAME -n $BLUE_NAMESPACE -o yaml | grep -A 3 "selector:"
echo ""

# Verificar que el Service esté enrutando correctamente
echo "🧪 Verificando conectividad del Service..."
ENDPOINTS=$(kubectl get endpoints $SERVICE_NAME -n $BLUE_NAMESPACE -o jsonpath='{.subsets[*].addresses[*].ip}' | wc -w)

if [ "$ENDPOINTS" -eq 0 ]; then
  echo "❌ Error: El Service no tiene endpoints disponibles"
  echo "🔙 Realizando rollback automático..."
  kubectl patch service $SERVICE_NAME -n $BLUE_NAMESPACE -p '{"spec":{"selector":{"version":"v1"}}}'
  exit 1
fi

echo "✅ Service tiene $ENDPOINTS endpoint(s) activo(s)"
echo ""

# Mostrar estado de deployments
echo "📋 Estado final de deployments en producción:"
kubectl get deployments -n $BLUE_NAMESPACE -l app=crud-backend

echo ""
echo "════════════════════════════════════════════════════"
echo "✅ Switch Blue→Green completado exitosamente"
echo "🎉 Producción ahora está ejecutando la versión Green (v2)"
echo ""
echo "💡 Próximos pasos:"
echo "   1. Monitorear métricas en producción"
echo "   2. Si todo está bien, el workflow actualizará Blue"
echo "   3. Green (staging) será escalado a 0 para liberar recursos"