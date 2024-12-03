#!/bin/bash

# Script pour afficher les informations sur l'infrastructure réseau d'un programme donné dans Adobe Cloud Manager,
# avec vérification de l'installation de bind9-dnsutils pour la résolution DNS, résolution des noms externes, et affichage de la région complète.

# Usage :
# ./list_network_infrastructures_program.sh <program_id>
# Exemple :
# ./list_network_infrastructures_program.sh 126952
# ref: https://developer.adobe.com/experience-cloud/cloud-manager/reference/api/#tag/Network-infrastructure/operation/getNetworkInfrastructures

# Vérification et installation de bind9-dnsutils si nécessaire
if ! command -v nslookup &> /dev/null; then
    echo "bind9-dnsutils n'est pas installé. Installation en cours..."
    sudo apt update
    sudo apt install -y bind9-dnsutils
fi

# Chargement des fonctions et variables de common.sh
source ../common/common.sh

# Vérifier que l'id du programme est fourni
program_id=$1
if [[ -z "$program_id" ]]; then
    echo "Erreur : Veuillez fournir l'ID du programme."
    exit 1
fi

# Récupérer la variable host_name depuis common.sh/variables.properties
host_name=$(check_variable "host_name")

# Définir un tableau de correspondance pour les noms de région
declare -A region_names=(
    ["aus5"]="Australia Southeast"
    ["can2"]="Canada"
    ["deu6"]="Germany"
    ["gbr9"]="UK South"
    ["jpn4"]="Japan"
    ["nld2"]="West Europe"
    ["sgp5"]="Singapore"
    ["va7"]="East US"
    ["wa1"]="West US"
)

# URL pour récupérer les informations sur l'infrastructure réseau
url="https://${host_name}/api/program/${program_id}/networkInfrastructures"

# Exécuter la requête pour récupérer les informations d'infrastructure réseau
response=$(curl -s -X GET "$url" \
    -H "x-api-key: $(check_variable 'api_key')" \
    -H "x-gw-ims-org-id: $(check_variable 'organization_id')" \
    -H "Authorization: Bearer $(check_variable 'access_token')")

# Vérifier si la réponse est un JSON valide
if echo "$response" | jq . >/dev/null 2>&1; then
    # Extraire les informations de l'infrastructure réseau
    infrastructures=$(echo "$response" | jq -c '._embedded.networkInfrastructures')
    
    # Vérifier si des infrastructures réseau existent
    if [[ -n "$infrastructures" && "$infrastructures" != "null" ]]; then
        echo "Informations sur l'infrastructure réseau pour le programme ${program_id} :"
        echo "$infrastructures" | jq -r '.[] | "\(.id) \(.kind) \(.status) \(.externalName) \(.region) \(.isPrimaryRegion)"' | while read -r id kind status externalName region isPrimaryRegion; do
            # Récupérer le libellé de la région
            region_label=${region_names[$region]}
            # Effectuer un nslookup pour chaque nom externe et extraire l'adresse IP
            ip_address=$(nslookup "$externalName" | awk '/^Address: / { print $2 }' | tail -n 1)
            # Afficher les informations formatées
            echo "ID: $id, Type: $kind, Statut: $status, Nom externe: $externalName, IP: ${ip_address:-Non résolue}, Région: $region ($region_label), Région principale: $isPrimaryRegion"
        done
    else
        echo "Aucune infrastructure réseau trouvée pour le programme ${program_id}."
    fi
else
    echo "Erreur : La réponse de l'API n'est pas au format JSON valide."
    echo "Réponse brute : $response"
    exit 1
fi
