# 📊 Monitoring Stack con Prometheus y Grafana



## 🎯 Descripción General

Este proyecto implementa un stack completo de monitoreo utilizando **Prometheus** y **Grafana** para supervisar una infraestructura híbrida que incluye:

- 🔷 **Cluster K3s**: 1 Master + 2 Workers
- 🔷 **Firewall pfSense**: Con NAT para acceso a redes internas
- 🔷 **Hipervisor Proxmox**: Virtualización y gestión de VMs
- 🔷 **Servidores Linux**: Monitoreo de métricas del sistema

**Características principales:**

- ✅ Recolección de métricas de todos los nodos (CPU, RAM, Disco, Red)
- ✅ Visualización en tiempo real con dashboards personalizados
- ✅ Acceso a través de NAT sin exposición directa de puertos
- ✅ Configuración completamente containerizada con Podman
- ✅ Fácil extensión para agregar nuevos exporters

------

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────────────────┐
│                     RED WAN (192.168.1.0/24)                    │
│                                                                 │
│  ┌────────────────┐           ┌──────────────────────────────┐  │
│  │   Servidor     │           │         pfSense              │  │
│  │  de Monitoreo  │           │  ┌──────────────────────┐    │  │
│  │                │           │  │    WAN: 192.168.1.2  │    │  │
│  │  ┌──────────┐  │           │  └──────────────────────┘    │  │
│  │  │Podman    │  │           │                              │  │
│  │  │Compose   │  │           │   NAT (Port Forward)         │  │
│  │  │ Stack    │  │           │  ┌────────────────────────┐  │  │
│  │  │          │  │           │  │ 9001 → 10.0.0.100:9100 │  │  │
│  │  │Prometheus│  │           │  │ 9002 → 10.0.0.101:9100 │  │  │
│  │  │Grafana   │  │           │  │ 9003 → 10.0.0.102:9100 │  │  │
│  │  │Loki      │  │           │  └────────────────────────┘  │  │
│  │  └──────────┘  │           │                              │  │
│  └──────┬─────────┘           └────────────┬─────────────────┘  │
│         │                                  │                    │
└─────────┼──────────────────────────────────┼────────────────────┘
          │                                  │
          │                                  │
          └──────────────┬───────────────────┘
                         │
                         │
                ┌────────▼────────────────┐
                │  RED LAN (10.0.0.0/24)  │
                │                         │
                │  ┌─────────────┐        │
                │  │ K3s Master  │        │
                │  │10.0.0.100   │        │
                │  │NodeExporter │        │
                │  └─────────────┘        │
                │                         │
                │  ┌─────────────┐        │
                │  │ K3s Worker1 │        │
                │  │10.0.0.101   │        │
                │  │NodeExporter │        │
                │  └─────────────┘        │
                │                         │
                │  ┌─────────────┐        │
                │  │ K3s Worker2 │        │
                │  │10.0.0.102   │        │
                │  │NodeExporter │        │
                │  └─────────────
```


------

## 🏗️ Implementación

El stack de monitoreo se despliega mediante **Podman Compose** en un servidor dedicado dentro de la red WAN (192.168.1.0/24). Los componentes principales son:

- **Prometheus**: Recolecta y almacena las métricas
- **Grafana**: Visualiza los datos en dashboards
- **Loki**: Almacena y consulta logs (opcional)

**Acceso a nodos internos:**
Los nodos del cluster K3s se encuentran en la red LAN (10.0.0.0/24) detrás del firewall pfSense. Para permitir el acceso desde Prometheus, se configuran reglas de **Port Forwarding** en pfSense que redirigen puertos específicos hacia cada nodo.

------

## 🖥️ Infraestructura Monitoreada

| Componente                | IP            | Servicio                          |
| :------------------------ | :------------ | :-------------------------------- |
| **Servidor de Monitoreo** | Variable      | Prometheus (9090), Grafana (3000) |
| **pfSense**               | 192.168.1.2   | Prometheus Exporter pfSense (9900) |
| **K3s Master**            | 10.0.0.100    | Node Exporter (9100)              |
| **K3s Worker 1**          | 10.0.0.101    | Node Exporter (9100)              |
| **K3s Worker 2**          | 10.0.0.102    | Node Exporter (9100)              |
| **Proxmox**               | 192.168.1.250 | Node Exporter (9100)              |
| **Bastion**               | 192.168.1.5   | Node Exporter (9100, opcional)    |

------

## 🚀 Pasos de Implementación

### 1. Despliegue del Stack con Podman Compose

Se utiliza un archivo `docker-compose.yaml` que define los servicios de Prometheus, Grafana y Loki, junto con volúmenes persistentes para almacenar los datos. Los contenedores se conectan a través de una red de Podman llamada `monitor`, que se crea automáticamente al desplegar el stack.

```bash
podman-compose up -d
```

### 2. Configuración de Prometheus

El archivo `prometheus.yml` define los targets a monitorear:

- **Prometheus self-monitoring**: Para supervisar el propio Prometheus
- **K3s Nodes**: Acceso a través de pfSense usando diferentes puertos
- **Proxmox**: Monitoreo directo del hipervisor
- **pfSense**: Monitoreo del firewall

### 3. Instalación de Node Exporters

Se instala **Node Exporter** en todos los nodos para exponer métricas del sistema:

- **En Proxmox**: Instalación vía `apt` y habilitación del servicio
- **En nodos K3s**: Instalación vía `apt` en cada nodo
- **En pfSense**: Instalación desde el Package Manager o vía SSH

Alternativamente, en cualquier nodo Linux con systemd se puede usar el script `components/install_node_exporter.sh` (ejecutar como root), que descarga el binario, crea un usuario de sistema y configura el servicio `node_exporter` para escuchar en `0.0.0.0:9100`.

### 4. Configuración de Red en pfSense

Para acceder a los nodos K3s desde la red WAN, se configuran reglas de **Port Forwarding**:

- Puerto 9001 → Master (10.0.0.100:9100)
- Puerto 9002 → Worker 1 (10.0.0.101:9100)
- Puerto 9003 → Worker 2 (10.0.0.102:9100)

Esto permite que Prometheus acceda a todos los nodos a través de la IP WAN de pfSense (192.168.1.2) usando diferentes puertos.

### 5. Configuración de Grafana

Grafana se configura de forma automática mediante **provisioning** (directorio `grafana/provisioning/` montado en el contenedor):

- **Data Sources**: Prometheus (`http://prometheus:9090`, por defecto) y Loki (`http://loki:3100`) se registran automáticamente al arrancar (`grafana/provisioning/datasources/datasources.yml`).
- **Dashboards**: Los JSON de `grafana/dashboards/` (uno por ID de grafana.com) se cargan automáticamente en la carpeta **Monitoring** (`grafana/provisioning/dashboards/dashboards.yml`).

Para añadir un dashboard nuevo: descárgalo en `grafana/dashboards/<id>.json` (p. ej. `curl https://grafana.com/api/dashboards/<ID>/revisions/latest/download -o grafana/dashboards/<id>.json`) y Grafana lo detectará en ~30s o tras `podman-compose restart grafana`.

> **⚠️ Seguridad**: El acceso inicial de Grafana usa `admin`/`admin` (ver `docker-compose.yaml`). Cámbialo en el primer inicio desde `Administration → Users`, o configura `GF_SECURITY_ADMIN_PASSWORD` con una contraseña segura antes de desplegar.

------

## 📊 Dashboards Incluidos (provisionados)

Los siguientes dashboards se cargan automáticamente en la carpeta **Monitoring** de Grafana desde el directorio `grafana/dashboards/`:

| Componente      | ID    | Dashboard                        | Descripción                                                                                                | Archivo            |
| :-------------- | :---- | :------------------------------- | :--------------------------------------------------------------------------------------------------------- | :----------------- |
| **Nodos**       | 13978 | Node Exporter Quickstart         | Métricas del sistema (CPU, memoria, disco, red) del Node Exporter, con variables para seleccionar instancia | `13978.json`       |
| **pfSense**     | 16877 | pfSense con Prometheus           | Monitorización del firewall: interfaces WAN/LAN, tráfico, CPU y estado de los servicios del pfSense         | `16877.json`       |
| **K3s Cluster** | 25400 | K3S Cluster Monitoring           | Estado del cluster K3s: nodos, pods, uso de recursos y salud general                                        | `25400.json`       |
| **K3s Cluster** | 22523 | Kubernetes Dashboard             | Vista completa de Kubernetes: workloads, servicios, pods y consumos por namespace                           | `22523.json`       |
| **Proxmox**     | 24550 | Proxmox VE - pve-exporter        | Métricas del hipervisor Proxmox: nodos PVE, VMs, CPU, memoria y almacenamiento                              | `24550.json`       |

> **Nota**: Los dashboards de K3s/Proxmox requieren que sus exporters expongan las métricas correspondientes (`kube-state-metrics` y `pve-exporter`) para mostrar datos; el dashboard se carga igualmente aunque los paneles estén vacíos.

------

## 🔍 Verificación y Troubleshooting

### Verificar Targets en Prometheus

Acceder a la interfaz web de Prometheus (`http://<IP>:9090/targets`) para confirmar que todos los targets estén en estado **UP**.

### Probar Acceso a Cada Nodo

Desde el servidor de monitoreo, se puede probar la conectividad a cada nodo utilizando `curl` o scripts de verificación que comprueban la disponibilidad del puerto 9100.

### Solución de Problemas Comunes

| Problema                 | Solución                                                   |
| :----------------------- | :--------------------------------------------------------- |
| **Target DOWN**          | Verificar que Node Exporter esté corriendo en el nodo      |
| **Target DOWN**          | Revisar reglas de firewall o NAT en pfSense                |
| **Sin datos en Grafana** | Verificar la URL del Data Source: `http://prometheus:9090` |
| **pfSense no responde**  | Configurar el exporter de pfSense para escuchar en `0.0.0.0:9900` |

------

## 🔧 Mantenimiento

### Comandos Útiles

- `podman ps -a | grep monitoring-` - Ver estado de contenedores
- `podman logs monitoring-prometheus --tail 50` - Ver logs de Prometheus
- `podman kill -s HUP monitoring-prometheus` - Recargar configuración sin reiniciar

### Actualizaciones

- `podman-compose pull` - Actualizar imágenes
- `podman-compose up -d` - Reiniciar con nuevas imágenes

------



## 📝 Autor & Licencia

Este documentacion forma parte de los ensayos en mi HomeLab. Ha sido comprobado y esta operativo. Puede ser descargado y utilizado como punto de partida para desplegar el monitoreo de su infraestructura.  

Por: *datenmaniak*