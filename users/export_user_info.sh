#!/bin/bash

# Charger les variables nécessaires
source ../common/common.sh

# Récupérer les variables depuis le fichier de configuration
api_key=$(check_variable "api_key")
organization_id=$(check_variable "organization_id")
access_token=$(check_variable "access_token")
host_name="usermanagement.adobe.io"

# Fonction pour afficher les erreurs
function afficher_erreur {
    echo "Erreur : $1"
    echo "Réponse brute : $2"
}

# Récupérer la liste des utilisateurs associés à l'organisation
echo "Récupération des utilisateurs associés à l'organisation..."
users_url="https://${host_name}/v2/usermanagement/${organization_id}/users"

users_response=$(curl -s -X GET "$users_url" \
  -H "x-api-key: $api_key" \
  -H "Authorization: Bearer $access_token" \
  -H "Content-Type: application/json")

# Vérifier si la réponse est valide
if ! echo "$users_response" | jq -e . >/dev/null 2>&1; then
    echo "Erreur : La réponse de l'API pour les utilisateurs n'est pas au format JSON valide."
    echo "Réponse brute : $users_response"
    exit 1
fi

# Extraire les IDs des utilisateurs
user_ids=$(echo "$users_response" | jq -r '.[] | .id')

# Initialiser le fichier CSV
csv_file="user_data.csv"
echo "User ID,Email,First Name,Last Name,Status,Username,Domain,User Type,Country Code,Groups" > "$csv_file"

# Parcourir chaque utilisateur et récupérer ses informations détaillées
for user_id in $user_ids; do
    echo "Traitement de l'utilisateur : $user_id"
    
    # Requête pour récupérer les détails de l'utilisateur
    user_details_url="https://${host_name}/v2/usermanagement/${organization_id}/users/${user_id}"
    user_details_response=$(curl -s -X GET "$user_details_url" \
      -H "x-api-key: $api_key" \
      -H "Authorization: Bearer $access_token" \
      -H "Content-Type: application/json")

    # Vérifier si la réponse est valide
    if ! echo "$user_details_response" | jq -e . >/dev/null 2>&1; then
        afficher_erreur "Erreur lors de la récupération des informations pour l'utilisateur $user_id" "$user_details_response"
        continue
    fi

    # Vérifier si la réponse est un code d'erreur 429 (Trop de requêtes) et réessayer après un délai
    if echo "$user_details_response" | jq -e '.error_code == "429050"' >/dev/null 2>&1; then
        echo "Erreur 429 (Trop de requêtes) pour l'utilisateur $user_id. Tentative de nouvelle requête après un délai de 10 secondes."
        sleep 10  # Attendre 10 secondes avant de réessayer
        user_details_response=$(curl -s -X GET "$user_details_url" \
          -H "x-api-key: $api_key" \
          -H "Authorization: Bearer $access_token" \
          -H "Content-Type: application/json")
    fi

    # Extraire les données pertinentes pour chaque utilisateur
    user_email=$(echo "$user_details_response" | jq -r '.email // empty')
    user_first_name=$(echo "$user_details_response" | jq -r '.firstName // empty')
    user_last_name=$(echo "$user_details_response" | jq -r '.lastName // empty')
    user_status=$(echo "$user_details_response" | jq -r '.status // empty')
    user_username=$(echo "$user_details_response" | jq -r '.username // empty')
    user_domain=$(echo "$user_details_response" | jq -r '.domain // empty')
    user_user_type=$(echo "$user_details_response" | jq -r '.userType // empty')
    user_country_code=$(echo "$user_details_response" | jq -r '.countryCode // empty')

    # Récupérer les groupes associés à l'utilisateur
    user_groups=$(echo "$user_details_response" | jq -r '.groups | join(", ") // empty')

    # Ajouter les données de l'utilisateur dans le fichier CSV
    echo "$user_id,$user_email,$user_first_name,$user_last_name,$user_status,$user_username,$user_domain,$user_user_type,$user_country_code,$user_groups" >> "$csv_file"

    # Pause entre les requêtes pour respecter la limite d'API
    sleep 3
done

echo "Les informations ont été enregistrées dans $csv_file"
