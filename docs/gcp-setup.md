# Guia de Setup Google Cloud Platform (GCP)

## Passo 1: Verificar se gcloud está instalado

```bash
gcloud --version
```

Se NÃO estiver instalado, instalar:

```bash
# Para Linux (Debian/Ubuntu)
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud init
```

## Passo 2: Autenticação

```bash
# Isso abrirá um navegador para login com sua conta Google
gcloud auth login
```

## Passo 3: Criar/Selecionar Projeto

```bash
# Listar projetos existentes
gcloud projects list

# Ou criar um novo
gcloud projects create distributed-log-$(date +%s) --name="Distributed Log System"

# Configurar projeto ativo
gcloud config set project PROJECT_ID_AQUI
```

## Passo 4: Habilitar APIs necessárias

```bash
# Habilitar Compute Engine API
gcloud services enable compute.googleapis.com

# Habilitar Artifact Registry API (para imagens Docker)
gcloud services enable artifactregistry.googleapis.com

# Habilitar Container Registry API (legacy, mas ainda necessário)
gcloud services enable containerregistry.googleapis.com
```

## Passo 5: Configurar região por padrão

```bash
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a
```

## Passo 6: Verificar credenciais

```bash
gcloud auth list
gcloud config list
```

## Notas Importantes

- **Custo:** As VMs e2-micro podem entrar no free tier (750 horas/mês grátis)
- **Região:** us-central1 (Iowa) costuma ser a mais barata
- **Firewall:** Precisaremos criar regras para portas 80, 443, 8000-8100
- **Billing:** Certifique-se de ter billing habilitado no seu projeto

## Variáveis que precisaremos

```bash
# Exportar para usar em scripts
export GCP_PROJECT_ID="seu-project-id-aqui"
export GCP_REGION="us-central1"
```

## Comando Rápido para Tudo

```bash
# Salvar no ~/.bashrc para persistência
echo 'export GCP_PROJECT_ID="seu-project-id"' >> ~/.bashrc
source ~/.bashrc
```
