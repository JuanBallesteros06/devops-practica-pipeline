#!/bin/bash
set -e

NAMESPACE=${1:-staging}
SERVICE_NAME="crud-backend-service-green"
MAX_RETRIES=10
RETRY_INTERVAL=5

echo "🧪 Ejecutando Smoke Tests en ambiente: $NAMESPACE"
echo "════════════════════════════════════════════════════"

# Obtener el ClusterIP del servicio
SERVICE_IP=$(kubectl get svc $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.clusterIP}')

if [ -z "$SERVICE_IP" ]; then
  echo "❌ Error: No se pudo obtener la IP del servicio $SERVICE_NAME"
  exit 1
fi

echo "📍 Service IP: $SERVICE_IP"
echo ""

# Test 1: Health Check
echo "Test 1: Health Check endpoint..."
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  HTTP_CODE=$(kubectl run curl-test --image=curlimages/curl:latest --rm -i --restart=Never -n $NAMESPACE -- \
    curl -s -o /dev/null -w "%{http_code}" http://$SERVICE_IP/healthz 2>/dev/null || echo "000")

  if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Health check exitoso (HTTP $HTTP_CODE)"
    break
  else
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "⏳ Intento $RETRY_COUNT/$MAX_RETRIES - Health check falló (HTTP $HTTP_CODE). Reintentando en ${RETRY_INTERVAL}s..."
    sleep $RETRY_INTERVAL
  fi
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
  echo "❌ FALLO: Health check no respondió después de $MAX_RETRIES intentos"
  exit 1
fi

# Test 2: API Response (ejemplo: endpoint raíz)
echo ""
echo "Test 2: Verificando respuesta del API..."
RESPONSE=$(kubectl run curl-test --image=curlimages/curl:latest --rm -i --restart=Never -n $NAMESPACE -- \
  curl -s http://$SERVICE_IP/ 2>/dev/null || echo "ERROR")

if [[ "$RESPONSE" == *"ERROR"* ]] || [ -z "$RESPONSE" ]; then
  echo "❌ FALLO: El API no respondió correctamente"
  exit 1
else
  echo "✅ API respondió correctamente"
  echo "📄 Respuesta: ${RESPONSE:0:100}..."
fi

# Test 3: Métricas de Prometheus
echo ""
echo "Test 3: Verificando endpoint de métricas..."
METRICS_CODE=$(kubectl run curl-test --image=curlimages/curl:latest --rm -i --restart=Never -n $NAMESPACE -- \
  curl -s -o /dev/null -w "%{http_code}" http://$SERVICE_IP/metrics 2>/dev/null || echo "000")

if [ "$METRICS_CODE" = "200" ]; then
  echo "✅ Endpoint de métricas accesible (HTTP $METRICS_CODE)"
else
  echo "⚠️  ADVERTENCIA: Endpoint de métricas no disponible (HTTP $METRICS_CODE)"
  # No fallamos el test por esto, es solo una advertencia
fi

# Test 4: Verificar que los pods estén running
echo ""
echo "Test 4: Verificando estado de los pods..."
NOT_RUNNING=$(kubectl get pods -n $NAMESPACE -l app=crud-backend,version=v2 --field-selector=status.phase!=Running --no-headers 2>/dev/null | wc -l)

if [ "$NOT_RUNNING" -gt 0 ]; then
  echo "❌ FALLO: Hay $NOT_RUNNING pods que no están en estado Running"
  kubectl get pods -n $NAMESPACE -l app=crud-backend,version=v2
  exit 1
else
  echo "✅ Todos los pods están Running"
  kubectl get pods -n $NAMESPACE -l app=crud-backend,version=v2
fi

echo ""
echo "════════════════════════════════════════════════════"
echo "✅ Todos los smoke tests pasaron exitosamente"
echo "🚀 Ambiente Green está listo para recibir tráfico"