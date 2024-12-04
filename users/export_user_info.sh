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

# URL de l'API pour la liste des utilisateurs
users_url="https://${host_name}/v2/usermanagement/${organization_id}/users"

# Récupérer la liste des utilisateurs
echo "Récupération de la liste des utilisateurs..."
users_response=$(curl -s -X GET "$users_url" \
  -H "x-api-key: $api_key" \
  -H "Authorization: Bearer $access_token" \
  -H "Content-Type: application/json")

# Vérifier si la réponse est valide
if ! echo "$users_response" | jq -e . >/dev/null 2>&1; then
    afficher_erreur "La réponse de l'API n'est pas au format JSON valide." "$users_response"
    exit 1
fi

# Initialiser le fichier CSV
csv_file="users_list.csv"
echo "User ID,Email,First Name,Last Name,Status,Username,Domain,User Type,Country Code,Groups" > "$csv_file"

# Extraire et écrire les données au format CSV
echo "$users_response" | jq -c '.[]' | while IFS= read -r user; do
    user_id=$(echo "$user" | jq -r '.id // empty')
    email=$(echo "$user" | jq -r '.email // empty')
    first_name=$(echo "$user" | jq -r '.firstName // empty')
    last_name=$(echo "$user" | jq -r '.lastName // empty')
    status=$(echo "$user" | jq -r '.status // empty')
    username=$(echo "$user" | jq -r '.username // empty')
    domain=$(echo "$user" | jq -r '.domain // empty')
    user_type=$(echo "$user" | jq -r '.userType // empty')
    country_code=$(echo "$user" | jq -r '.countryCode // empty')
    groups=$(echo "$user" | jq -r 'if .groups != null then .groups | join(", ") else "" end')

    # Écrire la ligne dans le CSV
    echo "$user_id,$email,$first_name,$last_name,$status,$username,$domain,$user_type,$country_code,$groups" >> "$csv_file"
done

echo "Les informations ont été enregistrées dans $csv_file"
