#!/bin/bash

# Script pour obtenir les statistiques d'utilisation d'un environnement dans Adobe Cloud Manager.
# Ce script utilise l'API Adobe pour récupérer des métriques sur les requêtes HTTP d'un environnement spécifique
# sur une période définie (par défaut les 7 derniers jours).
# 
# Ce script peut être utilisé pour générer un rapport de performance incluant le nombre de requêtes, les erreurs,
# et d'autres métriques de consommation de ressources sur l'environnement.
# 
# Usage :
# ./fetch_environment_metrics.sh <program_id> <environment_id> <days>
# Exemple pour le programme mutualisé (Programme Mutualisé Fondation AEM) avec l'environnement "programme-fondation-aem-prod" :
# 
# ./fetch_environment_metrics.sh 126952 1238855 7
#
# Arguments :
# <program_id> : L'identifiant du programme dans Adobe Cloud Manager.
# <environment_id> : L'identifiant de l'environnement spécifique dans le programme.
# <days> : Nombre de jours pour lesquels récupérer les statistiques (exemple : 7 pour les 7 derniers jours).

# Chargement des variables d'authentification et de configuration
source ../common/common.sh

# Récupérer la variable host_name depuis common.sh/variables.properties
host_name=$(check_variable "host_name")

# Paramètres d'entrée
program_id=$1
environment_id=$2
days=${3:-7}  # Par défaut, récupérer les statistiques des 7 derniers jours

# Vérification des paramètres
if [[ -z "$program_id" || -z "$environment_id" ]]; then
    echo "Erreur : Veuillez fournir l'ID du programme et l'ID de l'environnement."
    echo "Usage : $0 <program_id> <environment_id> <days>"
    exit 1
fi

# URL pour récupérer les statistiques d'utilisation de l'environnement
metrics_url="https://${host_name}/api/program/${program_id}/environment/${environment_id}/metrics?days=${days}"

# Exécuter la requête API pour récupérer les métriques d'utilisation
echo "Récupération des statistiques d'utilisation pour l'environnement ${environment_id} sur les ${days} derniers jours..."
response=$(curl -s -X GET "$metrics_url" \
     -H "x-api-key: $(check_variable 'api_key')" \
     -H "x-gw-ims-org-id: $(check_variable 'organization_id')" \
     -H "Authorization: Bearer $(check_variable 'access_token')")

# Vérification de la réponse JSON
if echo "$response" | jq . >/dev/null 2>&1; then
    echo "Statistiques d'utilisation pour l'environnement ${environment_id} :"
    echo "$response" | jq '.metrics[] | {metric: .id, value: .value, unit: .unit, description: .description}'
else
    echo "Erreur : La réponse de l'API n'est pas au format JSON valide."
    echo "Réponse brute : $response"
    exit 1
fi
