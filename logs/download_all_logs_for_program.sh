#!/bin/bash

# Charger les variables communes
source ./common/common.sh

# Vérification des paramètres
if [[ -z "$1" ]]; then
    echo "Erreur : Aucun PROGRAM_ID spécifié."
    echo "Usage : $0 <PROGRAM_ID>"
    exit 1
fi

PROGRAM_ID=$1
OUTPUT_DIR="./logs/output_logs"

# Fonction pour récupérer les environnements d'un programme
get_environments() {
    local program_id=$1
    echo "Récupération des environnements pour le programme $program_id..."
    ./program/list_program_environments.sh $program_id | jq -r '.[] | .id'
}

# Fonction pour télécharger les journaux d'un environnement
download_logs_for_environment() {
    local program_id=$1
    local environment_id=$2
    local output_dir=$3

    echo "Téléchargement des journaux pour l'environnement $environment_id du programme $program_id..."
    ./logs/download_logs.sh $program_id $environment_id "$output_dir/$program_id/$environment_id"
}

# Création de la structure de répertoires si nécessaire
prepare_output_directory() {
    local path=$1
    if [[ ! -d $path ]]; then
        echo "Création du répertoire : $path"
        mkdir -p "$path"
    fi
}

# Récupérer les environnements associés au programme
environments=$(get_environments $PROGRAM_ID)
if [[ -z "$environments" ]]; then
    echo "Aucun environnement trouvé pour le programme $PROGRAM_ID."
    exit 0
fi

# Télécharger les journaux pour chaque environnement
for ENVIRONMENT_ID in $environments; do
    ENV_OUTPUT_DIR="$OUTPUT_DIR/$PROGRAM_ID/$ENVIRONMENT_ID"
    prepare_output_directory "$ENV_OUTPUT_DIR"
    download_logs_for_environment $PROGRAM_ID $ENVIRONMENT_ID $OUTPUT_DIR
done

echo "Téléchargement des journaux terminé pour le programme $PROGRAM_ID."
