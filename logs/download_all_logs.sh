#!/bin/bash

# Script pour télécharger les journaux d'Adobe Cloud Manager pour un programme et un environnement donnés, sur une période de 7 jours.
# Ce script récupère les options de journaux disponibles pour l'environnement spécifié, puis télécharge les journaux pour chaque service
# et type de journal chaque jour pour les 7 derniers jours à partir de la date actuelle.
# Les journaux sont sauvegardés sous forme de fichiers .gz dans le répertoire output_logs/<program_id> avec un nom descriptif incluant
# la date, le service et le type de journal.

# Usage :
# ./download_all_logs.sh <program_id> <environment_id>
# Exemple :
# ./download_all_logs.sh 141858 1455199

# Chargement des variables d'authentification et de configuration
source ../common/common.sh

# Paramètres d'entrée
program_id=$1
environment_id=$2

# Récupérer la variable host_name depuis common.sh/variables.properties
host_name=$(check_variable "host_name")

# Chemin du répertoire de sortie
output_dir="output_logs/${program_id}"

# Créer le répertoire s'il n'existe pas déjà
mkdir -p "$output_dir"

# Récupération de la date actuelle
current_date=$(date +%Y-%m-%d)

# Étape 1 : Récupération des services de journaux disponibles pour l'environnement
echo "Étape 1 : Récupération des services de journaux disponibles"

# API pour obtenir les détails de l'environnement, incluant les options de journaux
environment_url="https://${host_name}/api/program/${program_id}/environment/${environment_id}"
response=$(curl -s -X GET "$environment_url" \
     -H "x-api-key: $(check_variable 'api_key')" \
     -H "x-gw-ims-org-id: $(check_variable 'organization_id')" \
     -H "Authorization: Bearer $(check_variable 'access_token')")

# Vérification et extraction des options de journaux
log_options=$(echo "$response" | jq -c '.availableLogOptions')
if [[ -z "$log_options" || "$log_options" == "null" ]]; then
    echo "Erreur : Aucun service de journaux disponible pour cet environnement. Veuillez vérifier les paramètres et l'authentification."
    exit 1
fi
echo "Réponse brute de l'API : $response"

# Étape 2 : Téléchargement des journaux pour chaque service et nom de journal
echo "Étape 2 : Téléchargement des journaux pour les 7 derniers jours, date de début : $current_date"
for (( day_offset=0; day_offset<7; day_offset++ )); do
    date_to_download=$(date -d "$current_date - $day_offset days" +%Y-%m-%d)
    echo "Téléchargement des journaux pour la date : $date_to_download"

    # Itération sur chaque option de journal
    echo "$log_options" | jq -c '.[]' | while read -r log_option; do
        service=$(echo "$log_option" | jq -r '.service')
        log_name=$(echo "$log_option" | jq -r '.name')
        
        # URL de l'API pour télécharger les journaux spécifiques
        download_url="https://${host_name}/api/program/${program_id}/environment/${environment_id}/logs/download?service=${service}&name=${log_name}&days=1&date=${date_to_download}"

        # Nom du fichier de sortie dans le répertoire spécifié
        output_file="${output_dir}/logs_${program_id}_${environment_id}_${service}_${log_name}_${date_to_download}.gz"
        
        echo "Téléchargement du journal pour ${service} - ${log_name} à l'URL : $download_url"

        # Téléchargement du fichier avec suivi des redirections
        curl -L -X GET "$download_url" \
             -H "x-api-key: $(check_variable 'api_key')" \
             -H "x-gw-ims-org-id: $(check_variable 'organization_id')" \
             -H "Authorization: Bearer $(check_variable 'access_token')" \
             --output "$output_file"

        # Vérification de la taille du fichier pour confirmer le téléchargement
        if [[ -s "$output_file" ]]; then
            echo "Téléchargement réussi : $output_file"
        else
            echo "Erreur : Le fichier $output_file est vide ou n'a pas été téléchargé correctement."
            rm -f "$output_file"  # Supprime le fichier vide pour éviter la confusion
        fi
    done
done
