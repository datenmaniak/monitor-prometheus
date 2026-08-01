#!/usr/bin/env bash
set -euo pipefail

VERSION="1.10.2"
ARCH="linux-amd64"
NODE_EXPORTER_USER="node_exporter"
INSTALL_DIR="/opt/node_exporter"

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: Ejecutar como root (sudo $0)." >&2
  exit 1
fi

if ! command -v systemctl >/dev/null 2>&1; then
  echo "ERROR: systemd no disponible; este script requiere systemd." >&2
  exit 1
fi

echo "[1/5] Descargando node_exporter v${VERSION}..."
curl -fsSL -o "/tmp/node_exporter-${VERSION}.tar.gz" \
  "https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/node_exporter-${VERSION}.${ARCH}.tar.gz"

echo "[2/5] Instalando binario en ${INSTALL_DIR}..."
mkdir -p "${INSTALL_DIR}"
tar -xzf "/tmp/node_exporter-${VERSION}.tar.gz" -C "${INSTALL_DIR}" --strip-components=1
rm -f "/tmp/node_exporter-${VERSION}.tar.gz"

echo "[3/5] Creando usuario de sistema '${NODE_EXPORTER_USER}'..."
id "${NODE_EXPORTER_USER}" &>/dev/null || useradd --no-create-home --system --shell /usr/sbin/nologin "${NODE_EXPORTER_USER}"

echo "[4/5] Configurando servicio systemd..."
cat >/etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
User=${NODE_EXPORTER_USER}
Group=${NODE_EXPORTER_USER}
Type=simple
ExecStart=${INSTALL_DIR}/node_exporter --web.listen-address=0.0.0.0:9100
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now node_exporter

echo "[5/5] Verificando métricas en localhost:9100..."
sleep 2
curl -fsS http://localhost:9100/metrics | head -n 5 \
  || echo "AVISO: no se pudo leer /metrics (revise firewall/contexto de red)."

echo "OK: node_exporter v${VERSION} instalado y ejecutándose."
