#!/bin/bash

# Ce script annule une étape spécifique d'exécution d'un pipeline dans Adobe Cloud Manager.
# Le script utilise une requête PUT pour annuler l'étape d'exécution en cours pour un pipeline donné.
# Il charge les fonctions et variables nécessaires depuis 'common.sh', vérifie les informations d'authentification (clé API, ID d'organisation, et jeton d'accès),
# et envoie la requête avec les en-têtes requis.

# Charger les fonctions et variables communes
source ../common/common.sh

# Vérification des arguments requis : ID du programme, ID du pipeline, et ID de l'exécution
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
  echo "Erreur : Veuillez fournir l'ID du programme, l'ID du pipeline et l'ID de l'exécution en arguments."
  echo "Usage : $0 <program_id> <pipeline_id> <execution_id>"
  exit 1
fi

program_id="$1"
pipeline_id="$2"
execution_id="$3"

# Récupérer la variable host_name depuis common.sh/variables.properties
host_name=$(check_variable "host_name")

# Préparation de la commande curl pour annuler l'étape d'exécution
curl_command="curl -s -w '%{http_code}' -X PUT \"https://${host_name}/api/program/$program_id/pipeline/$pipeline_id/execution/$execution_id/cancel\" \
-H 'x-api-key: $(check_variable "api_key")' \
-H 'x-gw-ims-org-id: $(check_variable "organization_id")' \
-H 'Authorization: Bearer $(check_variable "access_token")'"

# Exécuter la commande curl
execute_curl "$curl_command"
