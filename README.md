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
- ✅ Configuración completamente containerizada con Docker
- ✅ Fácil extensión para agregar nuevos exporters

------

## 🏗️ Arquitectura

text

```
┌─────────────────────────────────────────────────────────────────┐
│                     RED WAN (192.168.1.0/24)                    │
│                                                                 │
│  ┌────────────────┐           ┌──────────────────────────────┐  │
│  │   Servidor     │           │         pfSense              │  │
│  │  de Monitoreo  │           │  ┌──────────────────────┐    │  │
│  │                │           │  │    WAN: 192.168.1.2  │    │  │
│  │  ┌──────────┐  │           │  └──────────────────────┘    │  │
│  │  │Docker    │  │           │                              │  │
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

El stack de monitoreo se despliega mediante **Docker Compose** en un servidor dedicado dentro de la red WAN (192.168.1.0/24). Los componentes principales son:

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
| **pfSense**               | 192.168.1.2   | Node Exporter (9100)              |
| **K3s Master**            | 10.0.0.100    | Node Exporter (9100)              |
| **K3s Worker 1**          | 10.0.0.101    | Node Exporter (9100)              |
| **K3s Worker 2**          | 10.0.0.102    | Node Exporter (9100)              |
| **Proxmox**               | 192.168.1.250 | Node Exporter (9100)              |

------

## 🚀 Pasos de Implementación

### 1. Despliegue del Stack con Docker Compose

Se utiliza un archivo `docker-compose.yaml` que define los servicios de Prometheus, Grafana y Loki, junto con volúmenes persistentes para almacenar los datos. Los contenedores se conectan a través de una red Docker llamada `monitor`.

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

### 4. Configuración de Red en pfSense

Para acceder a los nodos K3s desde la red WAN, se configuran reglas de **Port Forwarding**:

- Puerto 9001 → Master (10.0.0.100:9100)
- Puerto 9002 → Worker 1 (10.0.0.101:9100)
- Puerto 9003 → Worker 2 (10.0.0.102:9100)

Esto permite que Prometheus acceda a todos los nodos a través de la IP WAN de pfSense (192.168.1.2) usando diferentes puertos.

### 5. Configuración de Grafana

Se agrega Prometheus como **Data Source** en Grafana y se importan dashboards predefinidos para visualizar las métricas de cada componente.

------

## 📊 Dashboards Recomendados

| Componente      | Dashboard                 | ID    |
| :-------------- | :------------------------ | :---- |
| **K3s Cluster** | K3S Cluster Monitoring    | 25400 |
| **K3s Cluster** | Kubernetes Dashboard      | 22523 |
| **Proxmox**     | Proxmox VE - pve-exporter | 24550 |
| **pfSense**     | pfSense con Prometheus    | 16877 |
| **Nodos**       | Node Exporter Quickstart  | 13978 |

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
| **pfSense no responde**  | Configurar Node Exporter para escuchar en `0.0.0.0:9100`   |

------

## 🔧 Mantenimiento

### Comandos Útiles

- `docker ps -a | grep monitoring-` - Ver estado de contenedores
- `docker logs monitoring-prometheus --tail 50` - Ver logs de Prometheus
- `docker kill -s HUP monitoring-prometheus` - Recargar configuración sin reiniciar

### Actualizaciones

- `docker-compose pull` - Actualizar imágenes
- `docker-compose up -d` - Reiniciar con nuevas imágenes

------



## 📝 Autor & Licencia

Este documentacion forma parte de los ensayos en mi HomeLab. Ha sido comprobado y esta operativo. Puede ser descargado y utilizado como punto de partida para desplegar el monitoreo de su infraestructura.  

Por: *datenmaniak*