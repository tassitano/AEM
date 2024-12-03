#!/bin/bash

# Ce script récupère la liste des exécutions pour un pipeline spécifique dans un programme donné sur Adobe Cloud Manager.
# Il nécessite l'ID du programme et l'ID du pipeline comme arguments.
# Utilise des variables et fonctions d'authentification depuis 'common.sh'.

# Charger les fonctions et variables communes
source ../common/common.sh

# Vérification des arguments requis : ID du programme et ID du pipeline
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Erreur : Veuillez fournir l'ID du programme et l'ID du pipeline en arguments."
  echo "Usage : $0 <program_id> <pipeline_id>"
  exit 1
fi

# Récupérer la variable host_name depuis common.sh/variables.properties
host_name=$(check_variable "host_name")

# Affectation des arguments à des variables
program_id="$1"
pipeline_id="$2"

# Construction de l'URL de l'API pour obtenir les exécutions du pipeline
api_url="https://${host_name}/api/program/${program_id}/pipeline/${pipeline_id}/executions"

# Préparation de la commande curl avec en-têtes d'authentification
curl_command="curl -s -w '%{http_code}' -X GET \"$api_url\" \
-H 'x-api-key: $(check_variable "api_key")' \
-H 'x-gw-ims-org-id: $(check_variable "organization_id")' \
-H 'Authorization: Bearer $(check_variable "access_token")'"

# Exécution de la commande curl
execute_curl "$curl_command"
