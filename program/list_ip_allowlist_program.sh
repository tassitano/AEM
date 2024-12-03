#!/bin/bash

# Script pour afficher la liste des IP allowlists pour un programme donné dans Adobe Cloud Manager.
# Ce script prend en paramètre l'ID du programme et renvoie la liste des IP autorisées.

# Usage :
# ./list_ip_allowlist_program.sh <program_id>
# Exemple :
# ./list_ip_allowlist_program.sh 126952
# ref: https://developer.adobe.com/experience-cloud/cloud-manager/reference/api/#tag/IP-Allowlist/operation/getProgramIPAllowlists
# Chargement des fonctions et variables de common.sh
source ../common/common.sh

# Vérifier que l'id du programme est fourni
program_id=$1
if [[ -z "$program_id" ]]; then
    echo "Erreur : Veuillez fournir l'ID du programme."
    exit 1
fi

# Récupérer la variable host_name depuis common.sh/variables.properties
host_name=$(check_variable "host_name")

# URL pour récupérer les IP allowlists du programme
url="https://${host_name}/api/program/${program_id}/ipAllowlists"

# Exécuter la requête pour récupérer la liste des IP allowlists
response=$(curl -s -X GET "$url" \
    -H "x-api-key: $(check_variable 'api_key')" \
    -H "x-gw-ims-org-id: $(check_variable 'organization_id')" \
    -H "Authorization: Bearer $(check_variable 'access_token')")

# Vérifier si la réponse est un JSON valide
if echo "$response" | jq . >/dev/null 2>&1; then
    # Extraire les éléments de l'array dans '_embedded.ipAllowlists'
    ip_allowlists=$(echo "$response" | jq -c '._embedded.ipAllowlists')
    
    # Vérifier si des IP allowlists existent
    if [[ -n "$ip_allowlists" && "$ip_allowlists" != "null" ]]; then
        echo "Liste des IP allowlists pour le programme ${program_id} :"
        echo "$ip_allowlists" | jq -r '.[] | "ID: \(.id), Nom: \(.name), IPs autorisées: \(.ipCidrSet | join(", "))"'
    else
        echo "Aucune IP allowlist trouvée pour le programme ${program_id}."
    fi
else
    echo "Erreur : La réponse de l'API n'est pas au format JSON valide."
    echo "Réponse brute : $response"
    exit 1
fi
