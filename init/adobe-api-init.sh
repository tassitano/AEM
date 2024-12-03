#!/bin/bash

# Ce script configure l'environnement pour l'accès aux APIs d'Adobe Cloud Manager en préparant les fichiers nécessaires.
# Il vérifie si `jq` est installé, crée des fichiers pour stocker les variables d'environnement, génère un fichier commun de fonctions,
# et génère des scripts individuels pour chaque requête de la collection Postman.
# De plus, il crée un script pour obtenir un jeton d'accès indépendant de common.sh.
# 
# Exemple d'exécution :
# ./adobe-api-init.sh
# Ce script va :
# 1. Vérifier la présence de jq, puis créer un fichier `variables.properties` pour stocker les variables nécessaires.
# 2. Générer un fichier `common.sh` avec les fonctions partagées pour exécuter les commandes.
# 3. Générer un script indépendant `obtain_access_token.sh` pour obtenir un jeton d'accès via Adobe IMS.
# 4. Créer des scripts individuels pour chaque requête de la collection JSON.
#
# Une fois terminé, modifiez `variables.properties` pour ajouter les valeurs de chaque variable et exécutez les scripts générés.

# Nom des fichiers avec underscores au lieu d'espaces
COLLECTION_FILE="Cloud_Manager_Public_API.postman_collection.json"
VARIABLES_FILE="variables.properties"

# Vérifie si jq est installé, sinon l'installer
if ! command -v jq &> /dev/null; then
    echo "Le programme jq n'est pas installé. Installation en cours..."
    sudo apt update
    sudo apt install -y jq
    echo "jq a été installé avec succès."
fi

# Vérifie si le fichier de collection est présent
if [[ ! -f "$COLLECTION_FILE" ]]; then
    echo "Le fichier $COLLECTION_FILE est manquant dans le répertoire courant."
    exit 1
fi

# Création du fichier variables.properties avec les clés extraites de la collection
echo "Création du fichier $VARIABLES_FILE avec les variables d'environnement..."
> "$VARIABLES_FILE" # Écrase le fichier existant

# Extraire les variables {{variable}} de la collection Postman et ajouter les variables spéciales
grep -o '{{[^}]*}}' "$COLLECTION_FILE" | sed 's/[{}]//g' | sort -u | while read -r key; do
    echo "$key=" >> "$VARIABLES_FILE"
done

# Ajout manuel des variables spécifiques si elles ne sont pas déjà présentes
for var in host_name ims_endpoint cloudmanager_claim; do
    if ! grep -q "^$var=" "$VARIABLES_FILE"; then
        echo "$var=" >> "$VARIABLES_FILE"
    fi
done

echo "Fichier $VARIABLES_FILE créé. Veuillez renseigner les valeurs en suivant le site https://developer.adobe.com."

# Création d'un fichier commun.sh pour externaliser les fonctions communes
cat > "common.sh" << 'EOF'
#!/bin/bash

# Vérification de la présence du fichier variables.properties
if [[ ! -f "variables.properties" ]]; then
    echo "Erreur : Le fichier variables.properties est manquant. Veuillez le créer et renseigner les valeurs."
    exit 1
fi

# Chargement des variables depuis variables.properties
declare -A variables
while IFS="=" read -r key value; do
    # Ignore les lignes vides et les commentaires
    [[ -z "$key" || "$key" == \#* ]] && continue
    variables[$key]=$value
done < "variables.properties"

# Vérification de l'initialisation de access_token
if [[ -z "${variables[access_token]}" || "${variables[access_token]}" == "{{access_token}}" ]]; then
    echo "Le token d'accès n'est pas initialisé. Exécution de obtain_access_token.sh pour obtenir un nouveau token..."
    if [[ -f "obtain_access_token.sh" ]]; then
        ./obtain_access_token.sh
        # Recharger les variables après l'obtention du nouveau token
        declare -A variables
        while IFS="=" read -r key value; do
            [[ -z "$key" || "$key" == \#* ]] && continue
            variables[$key]=$value
        done < "variables.properties"
        # Si après l'obtention, le token est toujours manquant, sortir avec une erreur
        if [[ -z "${variables[access_token]}" ]]; then
            echo "Erreur : Impossible d'obtenir le token d'accès. Veuillez vérifier le script obtain_access_token.sh."
            exit 1
        fi
    else
        echo "Erreur : Le script obtain_access_token.sh est manquant. Impossible de générer le token d'accès."
        exit 1
    fi
fi

# Fonction pour vérifier une variable, en utilisant les arguments passés au script
check_variable() {
    local var_name=$1
    local var_value=${variables[$var_name]}

    # Si la variable est vide, vérifier si elle est passée en argument
    if [[ -z "$var_value" ]]; then
        var_value=$(eval echo \$$var_name)
    fi

    # Si toujours vide après vérification des arguments, renvoyer une erreur
    if [[ -z "$var_value" ]]; then
        echo "Erreur : La variable $var_name n'est pas initialisée. Veuillez la renseigner dans variables.properties ou la passer en argument."
        exit 1
    fi

    echo "$var_value"
}

# Fonction pour exécuter une commande curl et gérer les erreurs
execute_curl() {
    local curl_command=$1
    echo "Exécution de la commande : $curl_command"
    eval "$curl_command"
    local status=$?

    if [[ $status -ne 0 ]]; then
        echo "Erreur lors de l'exécution de curl. Code de retour : $status"
        echo "Vérifiez les valeurs des variables utilisées dans la commande."
        exit 1
    fi
}
EOF

chmod +x "common.sh"
echo "Fichier common.sh généré et rendu exécutable."

# Parcours de chaque requête dans le fichier de collection JSON et création de scripts individuels
echo "Génération des scripts pour chaque requête dans la collection..."
jq -c '.item[]' "$COLLECTION_FILE" | while read -r item; do
    # Extraire le nom de la requête
    request_name=$(echo "$item" | jq -r '.name')
    
    # Continuer avec les requêtes valides
    request_name=$(echo "$request_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
    method=$(echo "$item" | jq -r '.request.method')
    url=$(echo "$item" | jq -r '.request.url.raw' 2>/dev/null || echo "")

    # Remplacer les variables {{variable}} dans l'URL avec la syntaxe Bash ${variable}
    url=$(echo "$url" | sed 's/{{\([^}]*\)}}/\$(check_variable "\1")/g')

    # Nom du fichier de script pour la requête
    script_file="${request_name}.sh"

    # Créer le contenu du script pour la requête en utilisant le fichier commun.sh pour alléger le code
    cat > "$script_file" << EOF
#!/bin/bash
source ./common.sh

# Préparation de la commande curl
curl_command="curl -s -w '%{http_code}' -X $method \"$url\" -H 'x-api-key: \$(check_variable "api_key")' -H 'x-gw-ims-org-id: \$(check_variable "organization_id")' -H 'Authorization: Bearer \$(check_variable "access_token")'"
execute_curl "\$curl_command"
EOF

    # Rendre le script exécutable
    chmod +x "$script_file"
    echo "Script $script_file généré et rendu exécutable."
done

# Création du script Obtain Access Token indépendant de common.sh
cat > "obtain_access_token.sh" << 'EOF'
#!/bin/bash

# Chargement direct des variables sans inclusion de common.sh pour éviter la boucle
if [[ ! -f "variables.properties" ]]; then
    echo "Erreur : Le fichier variables.properties est manquant. Veuillez le créer et renseigner les valeurs."
    exit 1
fi

# Charger les variables de variables.properties
declare -A variables
while IFS="=" read -r key value; do
    [[ -z "$key" || "$key" == \#* ]] && continue
    variables[$key]=$value
done < "variables.properties"

# Vérifier que les variables nécessaires sont définies
for var in api_key client_id client_secret scopes; do
    if [[ -z "${variables[$var]}" ]]; then
        echo "Erreur : La variable $var n'est pas initialisée dans variables.properties."
        exit 1
    fi
done

# Préparer la commande curl pour obtenir un token d'accès
curl_command="curl -s -X POST 'https://${variables[ims_endpoint]}/ims/token/v3' \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -d 'client_id=${variables[client_id]}&client_secret=${variables[client_secret]}&grant_type=client_credentials&scope=${variables[scopes]}'"

# Exécuter la commande curl et gérer les erreurs
echo "Exécution de la commande pour obtenir un token d'accès..."
response=$(eval "$curl_command")
if [[ $? -ne 0 ]]; then
    echo "Erreur lors de l'exécution de la commande : $curl_command"
    exit 1
fi

# Extraire le token d'accès et le sauvegarder dans variables.properties
access_token=$(echo "$response" | jq -r '.access_token')
if [[ -n "$access_token" && "$access_token" != "null" ]]; then
    sed -i.bak "/^access_token=/d" "variables.properties"
    echo "access_token=$access_token" >> "variables.properties"
    echo "Token d'accès mis à jour dans variables.properties."
else
    echo "Erreur lors de l'obtention du token d'accès : $response"
    exit 1
fi
EOF

# Rendre le script obtain_access_token.sh exécutable
chmod +x "obtain_access_token.sh"
echo "Script obtain_access_token.sh généré et rendu exécutable."

