#!/bin/bash

# Script pour lister les événements d'audit dans Adobe Experience Platform.

# Chargement des fonctions et variables communes
source ../common/common.sh

# Vérification des arguments requis
if [[ $# -ne 3 ]]; then
  echo "Erreur : Veuillez fournir les paramètres requis : <limit> <start> <sandbox_name>"
  echo "Usage : $0 <limit> <start> <sandbox_name>"
  exit 1
fi

# Paramètres d'entrée
limit=$1
start=$2
sandbox_name=$3

# Variables essentielles
access_token=$(check_variable "access_token")
api_key=$(check_variable "api_key")
org_id=$(check_variable "organization_id")

# Construction de l'URL et des en-têtes
url="https://platform.adobe.io/data/foundation/audit/events?limit=${limit}&start=${start}"
curl_command="curl -s -X GET \"$url\" \
  -H \"Authorization: Bearer $access_token\" \
  -H \"x-api-key: $api_key\" \
  -H \"x-gw-ims-org-id: $org_id\" \
  -H \"x-sandbox-name: $sandbox_name\""

# Affichage de la commande pour débogage
echo "Commande exécutée :"
echo "$curl_command"

# Exécution de la requête
response=$(eval "$curl_command")
status=$?

# Vérification du statut de la commande
if [[ $status -ne 0 ]]; then
  echo "Erreur lors de l'exécution de la commande cURL. Code de retour : $status"
  echo "Réponse complète de cURL : $response"
  exit 1
fi

# Vérification de la réponse JSON
if echo "$response" | jq . >/dev/null 2>&1; then
  echo "Résultats des événements d'audit :"
  echo "$response" | jq '.'
else
  echo "Erreur : La réponse de l'API n'est pas au format JSON valide."
  echo "Réponse brute : $response"
  echo "Commande exécutée : $curl_command"
  exit 1
fi
