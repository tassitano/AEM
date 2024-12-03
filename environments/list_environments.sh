#!/bin/bash

# Script pour récupérer et afficher les environnements associés à un programme Adobe Cloud Manager.
# Ce script utilise l'ID du programme fourni en paramètre pour faire une requête à l'API Cloud Manager
# et récupérer la liste des environnements, avec leurs ID, nom, description, type, et statut.

# Usage :
# ./list_environments.sh <program_id>
# Exemple d'exécution :
# ./list_environments.sh 123456
# (Le script récupérera et affichera les environnements associés au programme avec l'ID 123456.)

# Charger les fonctions et variables de common.sh
source ../common/common.sh

program_id=$1

# Vérifier que l'id du programme est fourni
if [[ -z "$program_id" ]]; then
    echo "Erreur : Veuillez fournir l'id du programme."
    exit 1
fi

# Récupérer le host_name depuis variables.properties
host_name=$(check_variable "host_name")

# URL pour récupérer les environnements associés au programme
url="https://${host_name}/api/program/$program_id/environments"

# Exécution de la requête pour récupérer les environnements
response=$(curl -s -X GET "$url" -H "x-api-key: $(check_variable 'api_key')" -H "x-gw-ims-org-id: $(check_variable 'organization_id')" -H "Authorization: Bearer $(check_variable 'access_token')")

# Vérifier que la réponse est un JSON valide
if echo "$response" | jq . >/dev/null 2>&1; then
    # Vérifier si "_embedded.environments" est présent et non nul dans la réponse
    environments=$(echo "$response" | jq -e '._embedded.environments // empty')
    
    if [[ -n "$environments" ]]; then
        # Formater la réponse pour ne conserver que les champs souhaités
        echo "$response" | jq '{ "_embedded": { "environments": [._embedded.environments[] | {id, programId, name, description, type, status}] } }'
    else
        echo "Aucun environnement trouvé pour le programme avec l'id $program_id."
    fi
else
    echo "Erreur : La réponse de l'API n'est pas au format JSON valide."
    echo "Réponse brute : $response"
    exit 1
fi
