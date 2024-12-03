#!/bin/bash

# Ce script récupère l'historique des exécutions pour un pipeline spécifique dans Adobe Cloud Manager.
# Il utilise une requête GET pour interroger l'API Cloud Manager et obtenir la liste des exécutions passées pour un pipeline donné.
# Le script charge les variables et fonctions depuis 'common.sh', vérifie les informations d'authentification nécessaires,
# et envoie la requête avec les en-têtes requis.

# Charger les fonctions et variables communes
source ../common/common.sh

# Récupérer la variable host_name depuis common.sh/variables.properties
host_name=$(check_variable "host_name")

# Vérification des arguments requis : ID du programme et ID du pipeline
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Erreur : Veuillez fournir l'ID du programme et l'ID du pipeline en arguments."
  echo "Usage : $0 <program_id> <pipeline_id>"
  exit 1
fi

program_id="$1"
pipeline_id="$2"

# Préparation de la commande curl pour récupérer les exécutions du pipeline
curl_command="curl -s -w '%{http_code}' -X GET \"https://${host_name}/api/program/$program_id/pipeline/$pipeline_id/executions\" \
-H 'x-api-key: $(check_variable "api_key")' \
-H 'x-gw-ims-org-id: $(check_variable "organization_id")' \
-H 'Authorization: Bearer $(check_variable "access_token")'"

# Exécuter la commande curl
execute_curl "$curl_command"
