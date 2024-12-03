#!/bin/bash

# Script pour lister les régions d'un programme donné dans Adobe Cloud Manager.
# Ce script prend en paramètre l'ID du programme et renvoie les informations
# sur les régions associées, y compris l'identifiant de la région, son nom, sa localisation
# et une description compréhensible du nom de région.

# Usage :
# ./list_program_regions.sh <program_id>
# Exemple :
# ./list_program_regions.sh 126952

# Chargement des fonctions et variables communes
source ../common/common.sh

# Récupérer la variable host_name depuis common.sh/variables.properties
host_name=$(check_variable "host_name")

# Vérifier que l'id du programme est fourni en paramètre
program_id=$1
if [[ -z "$program_id" ]]; then
    echo "Erreur : Veuillez fournir l'ID du programme."
    echo "Usage : $0 <program_id>"
    exit 1
fi

# URL de l'API pour lister les régions d'un programme donné
url="https://${host_name}/api/program/${program_id}/regions"

# Exécution de la requête curl pour obtenir les régions
response=$(curl -s -X GET "$url" \
    -H "x-api-key: $(check_variable 'api_key')" \
    -H "x-gw-ims-org-id: $(check_variable 'organization_id')" \
    -H "Authorization: Bearer $(check_variable 'access_token')")

# Vérification de la réponse et affichage des régions si elles sont disponibles
if echo "$response" | jq . >/dev/null 2>&1; then
    regions=$(echo "$response" | jq -e '._embedded.regions // empty')
    if [[ -n "$regions" ]]; then
        echo "Régions associées au programme $program_id :"
        
        # Dictionnaire de correspondance des noms de régions avec leur description
        declare -A region_descriptions=(
            ["aus5"]="Australia Southeast"
            ["can2"]="Canada"
            ["deu6"]="Germany"
            ["gbr9"]="UK South"
            ["jpn4"]="Japan"
            ["nld2"]="West Europe"
            ["sgp5"]="Singapore"
            ["va7"]="East US"
            ["wa1"]="West US"
        )
        
        # Itération sur les régions et ajout de la description correspondante
        echo "$regions" | jq -c '.[]' | while read -r region; do
            region_id=$(echo "$region" | jq -r '.id')
            name=$(echo "$region" | jq -r '.name')
            location=$(echo "$region" | jq -r '.location')
            environment_type=$(echo "$region" | jq -r '.environmentType')

            # Récupérer la description de la région basée sur le nom
            description="${region_descriptions[$name]:-"Description non disponible"}"
            
            # Affichage de la région avec sa description
            echo "Région :"
            echo "  ID            : $region_id"
            echo "  Nom           : $name ($description)"
            echo "  Localisation  : $location"
            echo "  Type          : $environment_type"
            echo ""
        done
    else
        echo "Aucune région trouvée pour le programme avec l'ID $program_id."
    fi
else
    echo "Erreur : La réponse de l'API n'est pas au format JSON valide."
    echo "Réponse brute : $response"
    exit 1
fi
