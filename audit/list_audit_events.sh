#!/bin/bash

# Script pour interroger les événements d’audit de Adobe Experience Platform.

# Usage :
# ./audit_query.sh <start_date> <end_date> <sandbox_name>
# Exemple :
# ./audit_query.sh 2024-01-01 2024-01-31 prod

# Charger les variables depuis common.sh
source ../common/common.sh

# Paramètres d'entrée
start_date=$1
end_date=$2
sandbox_name=$3

# Vérification des paramètres d'entrée
if [[ -z "$start_date" || -z "$end_date" || -z "$sandbox_name" ]]; then
    echo "Erreur : Veuillez fournir la date de début, la date de fin et le nom du sandbox."
    echo "Usage : $0 <start_date> <end_date> <sandbox_name>"
    exit 1
fi

# Récupérer les variables d’authentification
host_name=$(check_variable "host_name")

# URL de l'API
audit_url="https://${host_name}/audit-query/events?startDate=${start_date}&endDate=${end_date}"

# Exécution de la requête avec cURL
response=$(curl -s -X GET "$audit_url" \
    -H "Authorization: Bearer $(check_variable 'access_token')" \
    -H "x-api-key: $(check_variable 'api_key')" \
    -H "x-gw-ims-org-id: $(check_variable 'organization_id')" \
    -H "x-sandbox-name: $sandbox_name")

# Vérification de la réponse
if echo "$response" | jq . >/dev/null 2>&1; then
    echo "Événements d’audit pour la période du $start_date au $end_date :"
    echo "$response" | jq '.events[] | {timestamp, eventType, description}'
else
    echo "Erreur : Réponse non valide."
    echo "Réponse brute : $response"
fi
