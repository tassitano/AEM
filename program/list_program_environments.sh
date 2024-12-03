#!/bin/bash

# Script pour lister tous les environnements associés à un programme dans Adobe Cloud Manager.
# Usage :
# ./list_program_environments.sh <program_id>
# Exemple :
# ./list_program_environments.sh 126952
# ref: https://developer.adobe.com/experience-cloud/cloud-manager/reference/api/#tag/Environments/operation/getEnvironments

# Charger les fonctions et variables de common.sh
source ../common/common.sh

# Vérification des arguments
if [ -z "$1" ]; then
    echo "Erreur : Veuillez fournir l'ID du programme en paramètre."
    echo "Usage : $0 <program_id>"
    exit 1
fi

# Paramètre d'entrée
program_id=$1

# Récupération de la variable host_name depuis common.sh/variables.properties
host_name=$(check_variable "host_name")

# URL pour récupérer les environnements associés au programme
url="https://${host_name}/api/program/${program_id}/environments"

# Exécution de la requête cURL
echo "Récupération des environnements pour le programme ${program_id}..."
response=$(curl -s -X GET "$url" \
     -H "x-api-key: $(check_variable 'api_key')" \
     -H "x-gw-ims-org-id: $(check_variable 'organization_id')" \
     -H "Authorization: Bearer $(check_variable 'access_token')")

# Vérification que la réponse est un JSON valide
if echo "$response" | jq . >/dev/null 2>&1; then
    # Formater la réponse pour inclure uniquement les environnements et conserver le format original
    echo "$response" | jq '{_embedded: {environments: ._embedded.environments}}'
else
    echo "Erreur : La réponse de l'API n'est pas au format JSON valide."
    echo "Réponse brute : $response"
    exit 1
fi
