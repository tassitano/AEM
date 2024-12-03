#!/bin/bash

# Ce script obtient un token d'accès pour l'Adobe Experience Cloud en utilisant les informations d'identification
# et les paramètres stockés dans le fichier `variables.properties`. Le token obtenu est ensuite sauvegardé dans 
# le fichier pour une utilisation future dans les appels API.

# Exemple d'exécution :
# ./obtain_access_token.sh

# Chargement direct des variables sans inclusion de common.sh pour éviter la boucle
VARIABLES_FILE="../variables.properties"

# Vérification de la présence du fichier variables.properties
if [[ ! -f "$VARIABLES_FILE" ]]; then
    echo "Erreur : Le fichier $VARIABLES_FILE est manquant. Veuillez le créer et renseigner les valeurs."
    exit 1
fi

# Charger les variables de variables.properties
declare -A variables
while IFS="=" read -r key value; do
    [[ -z "$key" || "$key" == \#* ]] && continue
    variables[$key]=$value
done < "$VARIABLES_FILE"

# Afficher les valeurs des variables critiques pour le débogage
echo "Debug - Variables utilisées pour l'obtention du token :"
echo " - client_id: '${variables[client_id]}'"
echo " - client_secret: '${variables[client_secret]}'"
echo " - ims_endpoint: '${variables[ims_endpoint]}'"
echo " - scopes: '${variables[scopes]}'"

# Vérifier que les variables nécessaires sont définies
for var in client_id client_secret ims_endpoint scopes; do
    if [[ -z "${variables[$var]}" ]]; then
        echo "Erreur : La variable $var n'est pas initialisée dans $VARIABLES_FILE."
        exit 1
    fi
done

# Vérifier si le token existant est valide en faisant une requête simple
validate_token() {
    local token=$(grep -i 'access_token' "$VARIABLES_FILE" | cut -d'=' -f2)

    if [[ -z "$token" || "$token" == "{{access_token}}" ]]; then
        echo "Le token est inexistant ou invalide. Récupération d'un nouveau jeton..."
        return 1
    fi

    # Tester si le token actuel est valide
    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $token" https://api.adobe.com)

    if [[ "$response" != "200" ]]; then
        echo "Le token est invalide ou expiré. Récupération d'un nouveau jeton..."
        return 1
    fi

    echo "Le token est valide."
    return 0
}

# Si le token est valide, rien à faire
if validate_token; then
    exit 0
fi

# Préparer la commande curl pour obtenir un token d'accès
curl_command="curl -s -X POST 'https://${variables[ims_endpoint]}/ims/token/v3' \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -d 'client_id=${variables[client_id]}&client_secret=${variables[client_secret]}&grant_type=client_credentials&scope=${variables[scopes]}'"

# Exécuter la commande curl pour obtenir le token
echo "Exécution de la commande pour obtenir un token d'accès..."
response=$(eval "$curl_command" 2>&1)
curl_status=$?

# Vérification de l'exécution de curl
if [[ $curl_status -ne 0 ]]; then
    echo "Erreur lors de l'exécution de la commande curl."
    echo "Commande exécutée : $curl_command"
    echo "Réponse complète de curl :"
    echo "$response"
    exit 1
fi

# Extraction du token d'accès
access_token=$(echo "$response" | jq -r '.access_token')
if [[ -n "$access_token" && "$access_token" != "null" ]]; then
    # Sauvegarder le token d'accès dans variables.properties en remplaçant l'ancienne valeur
    sed -i.bak "/^access_token=/d" "$VARIABLES_FILE"
    echo "access_token=$access_token" >> "$VARIABLES_FILE"
    echo "Token d'accès mis à jour dans $VARIABLES_FILE."
    
    # Afficher le contenu du token d'accès
    echo "Contenu du token d'accès :"
    echo "$access_token"
else
    echo "Erreur lors de l'obtention du token d'accès : le champ access_token est manquant ou nul."
    echo "Réponse complète de l'API :"
    echo "$response"
    exit 1
fi
