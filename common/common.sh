#!/bin/bash

# Ce script charge les variables nécessaires depuis le fichier variables.properties et gère l'initialisation du token d'accès.
# Si le token d'accès n'est pas initialisé ou valide, il exécute obtain_access_token.sh pour en générer un nouveau.

# Vérification de la présence du fichier variables.properties
if [[ ! -f "../variables.properties" ]]; then
    echo "Erreur : Le fichier variables.properties est manquant. Veuillez le créer et renseigner les valeurs."
    exit 1
fi

# Chargement des variables depuis variables.properties
declare -A variables
while IFS="=" read -r key value; do
    [[ -z "$key" || "$key" == \#* ]] && continue
    variables[$key]=$value
done < "../variables.properties"

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

# Fonction pour vérifier une variable
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
