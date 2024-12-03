#!/bin/bash

# Ce script liste les programmes disponibles dans l'Adobe Experience Cloud en utilisant une requête vers l'API Cloud Manager.
# Il vérifie que la variable `host_name` est définie dans `variables.properties` et utilise les informations d'authentification
# pour accéder aux programmes disponibles dans l'organisation spécifiée.

source ../common/common.sh

# Vérifier que la variable host_name est définie
host_name=$(check_variable "host_name")

# URL pour lister les programmes, en utilisant host_name
url="https://${host_name}/api/programs"

# Préparation de la commande curl sans '%{http_code}' pour éviter d'inclure le code HTTP dans la réponse JSON
curl_command="curl -s -X GET \"$url\" -H 'x-api-key: $(check_variable "api_key")' -H 'x-gw-ims-org-id: $(check_variable "organization_id")' -H 'Authorization: Bearer $(check_variable "access_token")'"

# Exécuter la commande curl et capturer uniquement la sortie JSON
eval "$curl_command"
