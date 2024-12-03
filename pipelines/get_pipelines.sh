#!/bin/bash

# Ce script récupère la liste de toutes les pipelines associées à un programme spécifique dans Adobe Cloud Manager.
# Il s'appuie sur l'API d'Adobe Cloud Manager pour accéder aux informations des pipelines en fonction de l'ID du programme fourni.
# Le script charge des fonctions et variables communes depuis 'common.sh',
# vérifie les valeurs nécessaires (clé API, ID d'organisation et jeton d'accès),
# et envoie une requête GET pour obtenir la liste des pipelines.

# Charger les fonctions et variables communes
source ../common/common.sh

# Vérifier que l'ID du programme est fourni en argument
if [ -z "$1" ]; then
  echo "Erreur : Veuillez fournir l'ID du programme en argument."
  exit 1
fi

program_id="$1"

# Récupérer la variable host_name depuis common.sh/variables.properties
host_name=$(check_variable "host_name")

# Préparation de la commande curl pour récupérer la liste des pipelines
curl_command="curl -s -w '%{http_code}' -X GET \"https://${host_name}/api/program/$program_id/pipelines\" \
-H 'x-api-key: $(check_variable "api_key")' \
-H 'x-gw-ims-org-id: $(check_variable "organization_id")' \
-H 'Authorization: Bearer $(check_variable "access_token")'"

# Exécuter la commande curl
execute_curl "$curl_command"
