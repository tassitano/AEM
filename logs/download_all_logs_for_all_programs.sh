#!/bin/bash

# ----------------------------------------------------------------------
# Script : download_all_logs_for_all_programs.sh
#
# Description :
# Ce script récupère dynamiquement les journaux de tous les programmes
# disponibles dans Adobe Cloud Manager, ainsi que de leurs environnements
# associés. Le script utilise common.sh pour charger les variables et gérer
# l'obtention du jeton d'accès.
#
# ----------------------------------------------------------------------

# Charger les variables communes
source ./common/common.sh

# Vérifier que les variables et le jeton sont correctement chargés
token=$(check_variable "access_token")

# Fonction pour récupérer la liste des programmes
get_programs() {
    echo "Récupération de la liste des programmes..."
    programs_output=$(execute_curl "curl -s -X GET 'https://api.adobe.com/experience-manager/api/programs' -H 'Authorization: Bearer $token'")
    
    if [[ $? -ne 0 ]]; then
        echo "Erreur : Impossible de récupérer la liste des programmes."
        exit 1
    fi

    echo "$programs_output" | jq -r '.[] | select(.id != null) | .id'
}

# Fonction pour récupérer les environnements d'un programme
get_environments() {
    local program_id=$1
    echo "Récupération des environnements pour le programme $program_id..."
    environments_output=$(execute_curl "curl -s -X GET 'https://api.adobe.com/experience-manager/api/programs/$program_id/environments' -H 'Authorization: Bearer $token'")

    if [[ $? -ne 0 ]]; then
        echo "Erreur : Impossible de récupérer les environnements pour le programme $program_id."
        exit 1
    fi

    echo "$environments_output" | jq -r '.[] | select(.id != null) | .id'
}

# Fonction pour récupérer les journaux pour un programme et ses environnements
download_logs_for_program() {
    local program_id=$1
    echo "Récupération des journaux pour le programme $program_id..."
    execute_curl "curl -s -X GET 'https://api.adobe.com/experience-manager/api/programs/$program_id/logs' -H 'Authorization: Bearer $token'"

    if [[ $? -ne 0 ]]; then
        echo "Erreur : Impossible de télécharger les journaux pour le programme $program_id."
        exit 1
    fi
}

# Récupérer les programmes et leurs journaux
main() {
    echo "Démarrage de la récupération des journaux pour tous les programmes..."
    
    # Obtenir la liste des programmes
    programs=$(get_programs)
    
    if [[ -z "$programs" ]]; then
        echo "Aucun programme trouvé. Vérifiez vos permissions ou la connectivité."
        exit 1
    fi

    # Parcourir chaque programme
    for program_id in $programs; do
        echo "Traitement du programme : $program_id"
        
        # Récupérer les environnements du programme
        environments=$(get_environments $program_id)
        
        if [[ -z "$environments" ]]; then
            echo "Aucun environnement trouvé pour le programme $program_id."
            continue
        fi
        
        # Télécharger les journaux pour le programme et ses environnements
        download_logs_for_program $program_id
    done

    echo "Récupération terminée pour tous les programmes."
}

# Exécuter le script
main
