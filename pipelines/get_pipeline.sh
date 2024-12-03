#!/bin/bash

# Ce script récupère les détails d'une pipeline spécifique dans Adobe Cloud Manager.
# Il utilise l'API Adobe Cloud Manager pour accéder aux informations de la pipeline,
# en fonction de l'ID de programme et de l'ID de pipeline fournis.
# Le script charge des variables et fonctions communes à partir de 'common.sh',
# vérifie les variables nécessaires (clé API, ID d'organisation, et jeton d'accès),
# puis exécute une requête GET pour obtenir les détails de la pipeline spécifiée.
# Ce script peut être utilisé pour vérifier l'état ou la configuration d'une pipeline.

# Charge les variables et fonctions communes (comme check_variable et execute_curl)
source ../common/common.sh

# Définit l'ID de la pipeline et l'ID du programme. Ces valeurs doivent être remplacées par les ID réels.
pipeline_id="votre_pipeline_id"  # Remplace par l'ID de la pipeline cible
program_id="votre_program_id"    # Remplace par l'ID du programme auquel la pipeline appartient

# Récupérer la variable host_name depuis common.sh/variables.properties
host_name=$(check_variable "host_name")

# Construit l'URL pour appeler l'API Adobe Cloud Manager et obtenir les détails d'une pipeline spécifique
# Cette URL utilise l'ID de programme et l'ID de pipeline fournis.
url="https://${host_name}/api/program/${program_id}/pipeline/${pipeline_id}"

# Prépare la commande curl pour envoyer une requête GET à l'API avec les en-têtes nécessaires pour l'authentification
# - `x-api-key`, `x-gw-ims-org-id` et `Authorization` sont récupérés via check_variable dans common.sh
curl_command="curl -s -w '%{http_code}' -X GET \"$url\" \
  -H 'x-api-key: $(check_variable "api_key")' \
  -H 'x-gw-ims-org-id: $(check_variable "organization_id")' \
  -H 'Authorization: Bearer $(check_variable "access_token")'"

# Exécute la commande curl avec execute_curl (fonction provenant de common.sh)
# execute_curl gère l'exécution et peut inclure un traitement des erreurs basé sur le code de statut HTTP renvoyé.
execute_curl "$curl_command"
