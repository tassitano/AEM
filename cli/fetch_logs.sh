#!/bin/bash

# Inclure le fichier common.sh
source ./common.sh

# Définir des valeurs par défaut
DEFAULT_DAYS=7
DEFAULT_OUTPUT_DIR="./logs"
PROGRAM_ID=""
ENVIRONMENT_ID=""
DAYS="$DEFAULT_DAYS"
OUTPUT_DIR="$DEFAULT_OUTPUT_DIR"

# Vérifier si AIO est installé
check_aio_installed

# Vérification des arguments
if [ "$#" -eq 2 ]; then
    PROGRAM_ID="$1"
    ENVIRONMENT_ID="$2"
elif [ "$#" -eq 0 ]; then
    # Si aucun paramètre n'est fourni, demander à l'utilisateur de sélectionner un programme et un environnement
    select_program_and_environment
else
    echo "Usage: $0 <PROGRAM_ID> <ENVIRONMENT_ID>"
    exit 1
fi

# Vérifier si l'ID du programme et de l'environnement sont valides
check_empty "$PROGRAM_ID"
check_empty "$ENVIRONMENT_ID"

# Demander à l'utilisateur le nombre de jours pour les logs
echo "Entrez le nombre de jours pour les logs (défaut: $DEFAULT_DAYS) :"
read INPUT_DAYS
if [ ! -z "$INPUT_DAYS" ]; then
    DAYS="$INPUT_DAYS"
fi

# Définir le répertoire de sortie
echo "Entrez le répertoire de sortie pour les logs (défaut: $DEFAULT_OUTPUT_DIR) :"
read INPUT_OUTPUT_DIR
if [ ! -z "$INPUT_OUTPUT_DIR" ]; then
    OUTPUT_DIR="$INPUT_OUTPUT_DIR"
fi

# Créer le répertoire de sortie s'il n'existe pas
mkdir -p "$OUTPUT_DIR"

# Récupérer les options de logs
echo "Récupération des options de journaux pour l'environnement $ENVIRONMENT_ID..."
LOG_OPTIONS=$(aio cloudmanager logs:list --program-id "$PROGRAM_ID" --environment-id "$ENVIRONMENT_ID" --json | jq -r '.content[] | "\(.id) - \(.name)"')

if [ -z "$LOG_OPTIONS" ]; then
    echo "Échec de la récupération des options de journaux. Vérifiez les ID du programme et de l'environnement."
    exit 1
fi

# Afficher les options de logs et demander à l'utilisateur de sélectionner
echo "Sélectionnez le service de logs à télécharger :"
echo "$LOG_OPTIONS"
read LOG_CHOICE
LOG_OPTION=$(echo "$LOG_OPTIONS" | sed -n "${LOG_CHOICE}p" | cut -d ' ' -f1)

# Télécharger les logs pour le service sélectionné
echo "Téléchargement des logs pour le service $LOG_OPTION..."
aio cloudmanager logs:download --program-id "$PROGRAM_ID" --environment-id "$ENVIRONMENT_ID" --log-id "$LOG_OPTION" --days "$DAYS" --output-directory "$OUTPUT_DIR"

echo "Logs téléchargés avec succès dans $OUTPUT_DIR"
