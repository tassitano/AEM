#!/bin/bash

# Script pour télécharger un journal spécifique d'un environnement dans Adobe Cloud Manager.
# Ce script prend en paramètres l'ID du programme, l'ID de l'environnement, le service et le type de journal,
# le nombre de jours et une date spécifique. Il télécharge le journal correspondant et vérifie la réussite
# du téléchargement en validant la taille du fichier.

# Usage :
# ./download_logs.sh <program_id> <environment_id> <service> <log_name> <days> <date_param>
# Exemple :
# ./download_logs.sh 141858 1455199 author aemaccess 7 2024-11-01

# Chargement des variables d'authentification et de configuration depuis common.sh
source ../common/common.sh

# Récupérer la variable host_name depuis common.sh/variables.properties
host_name=$(check_variable "host_name")

# Paramètres d'entrée
program_id=$1
environment_id=$2
service=$3
log_name=$4
days=$5
date_param=$6

# Chemin du répertoire de sortie
output_dir="output_logs/${program_id}"

# Créer le répertoire s'il n'existe pas déjà
mkdir -p "$output_dir"

# Nom du fichier de sortie dans le répertoire spécifié
output_file="${output_dir}/logs_${program_id}_${environment_id}_${service}_${log_name}.gz"

# Étape 1 : Téléchargement du journal
echo "Étape 2 : Téléchargement des journaux"

# URL de l'API pour télécharger les journaux en utilisant host_name
download_url="https://${host_name}/api/program/${program_id}/environment/${environment_id}/logs/download?service=${service}&name=${log_name}&days=${days}&date=${date_param}"

# Exécution de la requête cURL avec suivi des redirections et vérification de la taille
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
