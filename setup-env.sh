#!/bin/bash
# ============================================================
# SETUP-ENV.SH - Configuration initiale du projet CRM
# ============================================================
# Ce script recupere les informations de votre environnement
# Power Platform et vous guide pour remplir les variables
# necessaires au projet.
#
# Usage : bash setup-env.sh
# ============================================================

set -e

echo "============================================================"
echo "  CONFIGURATION INITIALE - CRM Power Apps Code App"
echo "============================================================"
echo ""

# --- Couleurs ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Fichier de sortie ---
ENV_FILE=".env.project"

echo -e "${CYAN}Ce script va :${NC}"
echo "  1. Verifier que PAC CLI est installe et connecte"
echo "  2. Lister vos environnements Power Platform"
echo "  3. Vous demander vos informations entreprise"
echo "  4. Generer un fichier ${ENV_FILE} avec toutes les variables"
echo ""

# ============================================================
# ETAPE 1 : Verifier PAC CLI
# ============================================================
echo -e "${YELLOW}[1/4] Verification de PAC CLI...${NC}"

PAC_CMD=""
if command -v pac &> /dev/null; then
  PAC_CMD="pac"
elif [ -f "$LOCALAPPDATA/Microsoft/PowerAppsCLI/pac.cmd" ]; then
  PAC_CMD="$LOCALAPPDATA/Microsoft/PowerAppsCLI/pac.cmd"
elif [ -f "/c/Users/$USERNAME/AppData/Local/Microsoft/PowerAppsCLI/pac.cmd" ]; then
  PAC_CMD="/c/Users/$USERNAME/AppData/Local/Microsoft/PowerAppsCLI/pac.cmd"
fi

if [ -z "$PAC_CMD" ]; then
  echo -e "${RED}ERREUR : PAC CLI non trouve.${NC}"
  echo "Installez-le avec : winget install Microsoft.PowerAppsCLI"
  echo "Puis relancez ce script."
  PAC_AVAILABLE=false
else
  echo -e "${GREEN}PAC CLI trouve : $PAC_CMD${NC}"
  PAC_AVAILABLE=true
fi

# ============================================================
# ETAPE 2 : Lister les environnements Power Platform
# ============================================================
echo ""
echo -e "${YELLOW}[2/4] Recuperation des environnements Power Platform...${NC}"

if [ "$PAC_AVAILABLE" = true ]; then
  echo ""
  echo -e "${CYAN}--- Profil d'authentification actuel ---${NC}"
  "$PAC_CMD" auth list 2>/dev/null || echo -e "${RED}Aucun profil d'auth. Lancez : pac auth create${NC}"

  echo ""
  echo -e "${CYAN}--- Environnement actuel ---${NC}"
  "$PAC_CMD" env who 2>/dev/null || echo -e "${RED}Pas connecte a un environnement. Lancez : pac auth create --environment <ID>${NC}"

  echo ""
  echo -e "${CYAN}--- Liste des environnements disponibles ---${NC}"
  "$PAC_CMD" env list 2>/dev/null || echo -e "${RED}Impossible de lister les environnements.${NC}"

  echo ""
  echo -e "${CYAN}--- URL Dataverse de l'environnement actuel ---${NC}"
  ENV_URL=$("$PAC_CMD" env who 2>/dev/null | grep -i "url" | head -1 | awk '{print $NF}' || echo "")
  if [ -n "$ENV_URL" ]; then
    echo -e "${GREEN}URL detectee : $ENV_URL${NC}"
  else
    echo -e "${YELLOW}URL non detectee automatiquement.${NC}"
  fi
else
  echo -e "${YELLOW}PAC CLI non disponible, etape ignoree.${NC}"
  echo "Vous pourrez remplir les variables manuellement."
  ENV_URL=""
fi

# ============================================================
# ETAPE 3 : Collecte des informations entreprise
# ============================================================
echo ""
echo -e "${YELLOW}[3/4] Informations de votre entreprise...${NC}"
echo -e "${CYAN}(Appuyez sur Entree pour laisser vide et completer plus tard)${NC}"
echo ""

read -p "Nom de l'entreprise : " COMPANY_NAME
read -p "SIREN (9 chiffres) : " COMPANY_SIREN
read -p "Adresse complete : " COMPANY_ADDRESS
read -p "Email professionnel : " COMPANY_EMAIL
read -p "Telephone : " COMPANY_PHONE
read -p "Site web (URL) : " COMPANY_WEBSITE
read -p "URL du logo (pour les PDF) : " COMPANY_LOGO_URL
read -p "Nom complet de l'auteur du projet : " AUTHOR_NAME
echo ""
read -p "IBAN (pour mentions factures) : " COMPANY_IBAN
read -p "BIC : " COMPANY_BIC
echo ""

# URL Dataverse
if [ -z "$ENV_URL" ]; then
  read -p "URL Dataverse (ex: monorg.crm12.dynamics.com) : " DATAVERSE_URL
else
  echo -e "URL Dataverse detectee : ${GREEN}$ENV_URL${NC}"
  read -p "Confirmer ou saisir une autre URL (Entree pour garder) : " DATAVERSE_URL_INPUT
  DATAVERSE_URL=${DATAVERSE_URL_INPUT:-$ENV_URL}
fi

read -p "MSAL Client ID (Azure App Registration, laisser vide pour le defaut public) : " MSAL_CLIENT_ID
MSAL_CLIENT_ID=${MSAL_CLIENT_ID:-"A COMPLETER"}

# ============================================================
# ETAPE 4 : Generation du fichier .env.project
# ============================================================
echo ""
echo -e "${YELLOW}[4/4] Generation du fichier ${ENV_FILE}...${NC}"

cat > "$ENV_FILE" << EOF
# ============================================================
# VARIABLES DU PROJET CRM - Power Apps Code App
# ============================================================
# Ce fichier est genere par setup-env.sh
# Il contient les valeurs a utiliser pour remplacer les
# placeholders {{VARIABLE}} dans les documents du projet.
#
# IMPORTANT : Ne PAS committer ce fichier sur GitHub public !
# Ajoutez-le a votre .gitignore
# ============================================================

# --- Informations entreprise ---
NOM_ENTREPRISE="${COMPANY_NAME:-A COMPLETER}"
SIREN="${COMPANY_SIREN:-A COMPLETER}"
ADRESSE="${COMPANY_ADDRESS:-A COMPLETER}"
EMAIL="${COMPANY_EMAIL:-A COMPLETER}"
TELEPHONE="${COMPANY_PHONE:-A COMPLETER}"
SITE_WEB="${COMPANY_WEBSITE:-A COMPLETER}"
URL_LOGO="${COMPANY_LOGO_URL:-A COMPLETER}"
NOM_AUTEUR="${AUTHOR_NAME:-A COMPLETER}"

# --- Coordonnees bancaires (pour mentions factures) ---
IBAN="${COMPANY_IBAN:-A COMPLETER}"
BIC="${COMPANY_BIC:-A COMPLETER}"

# --- Power Platform ---
URL_DATAVERSE="${DATAVERSE_URL:-A COMPLETER}"
MSAL_CLIENT_ID="${MSAL_CLIENT_ID:-A COMPLETER}"

# --- Power Automate (URLs des flows HTTP trigger) ---
POWER_AUTOMATE_EMAIL_URL="A COMPLETER"
EOF

echo -e "${GREEN}Fichier ${ENV_FILE} genere avec succes !${NC}"
echo ""

# ============================================================
# Verifier le .gitignore
# ============================================================
if [ -f ".gitignore" ]; then
  if ! grep -q "$ENV_FILE" .gitignore; then
    echo "$ENV_FILE" >> .gitignore
    echo -e "${GREEN}${ENV_FILE} ajoute au .gitignore${NC}"
  fi
else
  echo "$ENV_FILE" > .gitignore
  echo -e "${GREEN}.gitignore cree avec ${ENV_FILE}${NC}"
fi

# ============================================================
# Resume
# ============================================================
echo ""
echo "============================================================"
echo -e "${GREEN}  CONFIGURATION TERMINEE${NC}"
echo "============================================================"
echo ""
echo "Fichier genere : ${ENV_FILE}"
echo ""
echo "Variables definies :"
echo "---"
cat "$ENV_FILE" | grep -E "^[A-Z]" | while IFS='=' read -r key value; do
  if [ "$value" = '"A COMPLETER"' ]; then
    echo -e "  ${RED}$key = A COMPLETER${NC}"
  else
    echo -e "  ${GREEN}$key = $value${NC}"
  fi
done
echo "---"
echo ""
echo "Pour appliquer ces variables dans les documents :"
echo "  bash apply-env.sh"
echo ""
echo "Pour relancer la configuration :"
echo "  bash setup-env.sh"
echo ""
