#!/bin/bash

# Script pour lister les variables d'un environnement spécifique d'un programme dans Adobe Cloud Manager.
# Usage :
# ./list_environment_variables.sh <program_id> <environment_id>
# Exemple :
# ./list_environment_variables.sh 126952 1238855
# ref: https://developer.adobe.com/experience-cloud/cloud-manager/reference/api/#tag/Variables/operation/getEnvironmentVariables

# Charger les fonctions et variables de common.sh
source ../common/common.sh

# Vérification des arguments
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Erreur : Veuillez fournir l'ID du programme et l'ID de l'environnement en paramètres."
    echo "Usage : $0 <program_id> <environment_id>"
    exit 1
fi

# Paramètres d'entrée
program_id=$1
environment_id=$2

# Récupération de la variable host_name depuis common.sh/variables.properties
host_name=$(check_variable "host_name")

# URL pour récupérer les variables d'un environnement
url="https://${host_name}/api/program/${program_id}/environment/${environment_id}/variables"

# Exécution de la requête cURL
echo "Récupération des variables pour l'environnement ${environment_id} dans le programme ${program_id}..."
response=$(curl -s -X GET "$url" \
     -H "x-api-key: $(check_variable 'api_key')" \
     -H "x-gw-ims-org-id: $(check_variable 'organization_id')" \
     -H "Authorization: Bearer $(check_variable 'access_token')")

# Vérification que la réponse est un JSON valide
if echo "$response" | jq . >/dev/null 2>&1; then
    # Formater la réponse pour inclure uniquement les variables et conserver le format original
    echo "$response" | jq '{_embedded: {variables: ._embedded.variables}}'
else
    echo "Erreur : La réponse de l'API n'est pas au format JSON valide."
    echo "Réponse brute : $response"
    exit 1
fi
