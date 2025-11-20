#!/bin/bash
set -e

echo "🔍 Iniciando análisis de Canary..."

NAMESPACE="production"
SERVICE="crud-backend-service"
PROMETHEUS_URL="http://prometheus.istio-system:9090"

# Función para obtener métricas de Prometheus
get_metric() {
  local query=$1
  local result=$(kubectl exec -n istio-system deployment/prometheus -c prometheus -- \
    wget -qO- --post-data="query=${query}" \
    "${PROMETHEUS_URL}/api/v1/query" 2>/dev/null | grep -o '"result":\[.*\]' || echo "")
  echo "$result"
}

echo "📊 Obteniendo métricas de v1 (baseline)..."

# Tasa de error v1 (últimos 5 minutos)
ERROR_RATE_V1=$(kubectl exec -n istio-system deployment/prometheus -c prometheus -- \
  wget -qO- --post-data='query=sum(rate(http_requests_total{app="crud-backend",version="v1",status=~"5.."}[5m]))/sum(rate(http_requests_total{app="crud-backend",version="v1"}[5m]))' \
  "${PROMETHEUS_URL}/api/v1/query" 2>/dev/null | grep -oP '"\d+\.\d+"' | head -1 | tr -d '"' || echo "0")

# Latencia p95 v1
LATENCY_V1=$(kubectl exec -n istio-system deployment/prometheus -c prometheus -- \
  wget -qO- --post-data='query=histogram_quantile(0.95,rate(http_request_duration_seconds_bucket{app="crud-backend",version="v1"}[5m]))' \
  "${PROMETHEUS_URL}/api/v1/query" 2>/dev/null | grep -oP '"\d+\.\d+"' | head -1 | tr -d '"' || echo "0")

echo "📊 Obteniendo métricas de v2 (canary)..."

# Tasa de error v2
ERROR_RATE_V2=$(kubectl exec -n istio-system deployment/prometheus -c prometheus -- \
  wget -qO- --post-data='query=sum(rate(http_requests_total{app="crud-backend",version="v2",status=~"5.."}[5m]))/sum(rate(http_requests_total{app="crud-backend",version="v2"}[5m]))' \
  "${PROMETHEUS_URL}/api/v1/query" 2>/dev/null | grep -oP '"\d+\.\d+"' | head -1 | tr -d '"' || echo "0")

# Latencia p95 v2
LATENCY_V2=$(kubectl exec -n istio-system deployment/prometheus -c prometheus -- \
  wget -qO- --post-data='query=histogram_quantile(0.95,rate(http_request_duration_seconds_bucket{app="crud-backend",version="v2"}[5m]))' \
  "${PROMETHEUS_URL}/api/v1/query" 2>/dev/null | grep -oP '"\d+\.\d+"' | head -1 | tr -d '"' || echo "0")

echo ""
echo "📈 Resultados del análisis:"
echo "════════════════════════════════════════"
echo "V1 (Baseline):"
echo "  - Error Rate: ${ERROR_RATE_V1:-0}%"
echo "  - Latency P95: ${LATENCY_V1:-0}s"
echo ""
echo "V2 (Canary):"
echo "  - Error Rate: ${ERROR_RATE_V2:-0}%"
echo "  - Latency P95: ${LATENCY_V2:-0}s"
echo "════════════════════════════════════════"

# Umbrales
MAX_ERROR_RATE=0.05  # 5%
MAX_LATENCY=2.0      # 2 segundos

# Validación de error rate
if (( $(echo "${ERROR_RATE_V2:-0} > $MAX_ERROR_RATE" | bc -l) )); then
  echo "❌ FALLO: Error rate del canary (${ERROR_RATE_V2}%) supera el umbral ($MAX_ERROR_RATE%)"
  exit 1
fi

# Validación de latencia
if (( $(echo "${LATENCY_V2:-0} > $MAX_LATENCY" | bc -l) )); then
  echo "❌ FALLO: Latencia del canary (${LATENCY_V2}s) supera el umbral (${MAX_LATENCY}s)"
  exit 1
fi

# Comparación con baseline (el canary no debe ser peor que v1)
if (( $(echo "${ERROR_RATE_V2:-0} > ${ERROR_RATE_V1:-0} * 1.5" | bc -l) )); then
  echo "❌ FALLO: Error rate del canary es 50% peor que baseline"
  exit 1
fi

echo ""
echo "✅ ÉXITO: Canary pasa todos los criterios de análisis"
echo "🚀 Procediendo con la promoción..."
exit 0