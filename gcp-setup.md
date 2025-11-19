# Guía de Setup Google Cloud Platform (GCP)

## Paso 1: Verificar si gcloud está instalado

```bash
gcloud --version
```

Si NO está instalado, instalar:

```bash
# Para Linux (Debian/Ubuntu)
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud init
```

## Paso 2: Autenticación

```bash
# Esto abrirá un navegador para login con tu cuenta Google
gcloud auth login
```

## Paso 3: Crear/Seleccionar Proyecto

```bash
# Listar proyectos existentes
gcloud projects list

# O crear uno nuevo
gcloud projects create distributed-log-$(date +%s) --name="Distributed Log System"

# Configurar proyecto activo
gcloud config set project PROJECT_ID_AQUI
```

## Paso 4: Habilitar APIs necesarias

```bash
# Habilitar Compute Engine API
gcloud services enable compute.googleapis.com

# Habilitar Artifact Registry API (para Docker images)
gcloud services enable artifactregistry.googleapis.com

# Habilitar Container Registry API (legacy, pero aún necesario)
gcloud services enable containerregistry.googleapis.com
```

## Paso 5: Configurar región por defecto

```bash
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a
```

## Paso 6: Verificar credenciales

```bash
gcloud auth list
gcloud config list
```

## Notas Importantes

- **Costo:** Las VMs e2-micro pueden entrar en free tier (750 horas/mes gratis)
- **Región:** us-central1 (Iowa) suele ser la más barata
- **Firewall:** Necesitaremos crear reglas para puertos 80, 443, 8000-8100
- **Billing:** Asegúrate de tener billing habilitado en tu proyecto

## Variables que necesitaremos

```bash
# Exportar para usar en scripts
export GCP_PROJECT_ID="tu-project-id-aqui"
export GCP_REGION="us-central1"
```

## Comando Rápido para Todo

```bash
# Guardar en ~/.bashrc para persistencia
echo 'export GCP_PROJECT_ID="tu-project-id"' >> ~/.bashrc
source ~/.bashrc
```
