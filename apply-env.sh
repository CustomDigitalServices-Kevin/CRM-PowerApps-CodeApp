#!/bin/bash
# ============================================================
# APPLY-ENV.SH - Applique les variables dans les documents
# ============================================================
# Remplace les placeholders {{VARIABLE}} dans les fichiers MD
# par les valeurs definies dans .env.project
#
# Usage : bash apply-env.sh
# ============================================================

set -e

ENV_FILE=".env.project"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

if [ ! -f "$ENV_FILE" ]; then
  echo -e "${RED}ERREUR : Fichier ${ENV_FILE} introuvable.${NC}"
  echo "Lancez d'abord : bash setup-env.sh"
  exit 1
fi

echo -e "${CYAN}Chargement des variables depuis ${ENV_FILE}...${NC}"

# Charger les variables
source "$ENV_FILE"

# Liste des fichiers a traiter
FILES=(
  "CDC_CRM_PowerApps_CodeApp.md"
  "COWORK_SETUP_CLAUDE_DIR_V2.md"
)

# Liste des substitutions
declare -A SUBSTITUTIONS=(
  ["{{NOM_ENTREPRISE}}"]="$NOM_ENTREPRISE"
  ["{{SIREN}}"]="$SIREN"
  ["{{ADRESSE}}"]="$ADRESSE"
  ["{{EMAIL}}"]="$EMAIL"
  ["{{TELEPHONE}}"]="$TELEPHONE"
  ["{{SITE_WEB}}"]="$SITE_WEB"
  ["{{URL_LOGO}}"]="$URL_LOGO"
  ["{{NOM_AUTEUR}}"]="$NOM_AUTEUR"
  ["{{IBAN}}"]="$IBAN"
  ["{{BIC}}"]="$BIC"
  ["{{URL_DATAVERSE}}"]="$URL_DATAVERSE"
  ["{{MSAL_CLIENT_ID}}"]="$MSAL_CLIENT_ID"
)

echo ""
echo -e "${YELLOW}Remplacement des placeholders...${NC}"

for file in "${FILES[@]}"; do
  if [ ! -f "$file" ]; then
    echo -e "  ${YELLOW}SKIP : $file (introuvable)${NC}"
    continue
  fi

  count=0
  for placeholder in "${!SUBSTITUTIONS[@]}"; do
    value="${SUBSTITUTIONS[$placeholder]}"
    if [ "$value" != "A COMPLETER" ] && [ -n "$value" ]; then
      # Compter les occurrences
      matches=$(grep -c "$placeholder" "$file" 2>/dev/null || echo "0")
      if [ "$matches" -gt 0 ]; then
        # Echapper les caracteres speciaux pour sed
        escaped_value=$(echo "$value" | sed 's/[&/\]/\\&/g')
        sed -i "s|${placeholder}|${escaped_value}|g" "$file"
        count=$((count + matches))
      fi
    fi
  done

  echo -e "  ${GREEN}$file : $count remplacements effectues${NC}"
done

# Verifier les placeholders restants
echo ""
echo -e "${CYAN}Verification des placeholders restants...${NC}"
REMAINING=0
for file in "${FILES[@]}"; do
  if [ -f "$file" ]; then
    leftover=$(grep -c '{{[A-Z_]*}}' "$file" 2>/dev/null || echo "0")
    if [ "$leftover" -gt 0 ]; then
      echo -e "  ${YELLOW}$file : $leftover placeholders restants${NC}"
      grep -n '{{[A-Z_]*}}' "$file" | head -10
      REMAINING=$((REMAINING + leftover))
    fi
  fi
done

if [ "$REMAINING" -eq 0 ]; then
  echo -e "  ${GREEN}Tous les placeholders ont ete remplaces !${NC}"
else
  echo ""
  echo -e "${YELLOW}Il reste $REMAINING placeholders non remplaces.${NC}"
  echo "Completez les valeurs dans ${ENV_FILE} puis relancez : bash apply-env.sh"
fi

echo ""
echo -e "${GREEN}Terminé !${NC}"
