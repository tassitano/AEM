#!/bin/bash

# Script pour récupérer tous les détails des environnements associés à un programme Adobe Cloud Manager.
# Ce script utilise l'ID du programme fourni en paramètre pour faire une requête à l'API Cloud Manager
# et récupérer les informations détaillées sur chaque environnement associé au programme.

# Usage :
# ./list_environments_details.sh <program_id>
# Exemple d'exécution :
# ./list_environments_details.sh 141858
# (Le script affichera les détails complets des environnements associés au programme avec l'ID 123456.)

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

# URL pour récupérer tous les détails des environnements associés au programme
url="https://${host_name}/api/program/$program_id/environments"

# Exécuter la requête pour récupérer tous les détails des environnements, et filtrer uniquement le JSON
curl -s -X GET "$url" -H "x-api-key: $(check_variable 'api_key')" -H "x-gw-ims-org-id: $(check_variable 'organization_id')" -H "Authorization: Bearer $(check_variable 'access_token')"
