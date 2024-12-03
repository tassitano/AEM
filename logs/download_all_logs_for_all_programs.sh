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

# Vérifie si les scripts externes nécessaires sont disponibles
check_dependencies() {
    if ! [ -x "$(command -v ./get_environments.sh)" ] || ! [ -x "$(command -v ./download_logs.sh)" ]; then
        echo "Les scripts nécessaires (get_environments.sh ou download_logs.sh) ne sont pas accessibles." >&2
        exit 1
    fi
}

# Télécharge les journaux pour tous les programmes
download_logs_for_all_programs() {
    # Récupère la liste des programmes
    local programs=$(./get_programs.sh)

    for program_id in $programs; do
        echo "Traitement du programme : $program_id"

        # Récupère les environnements pour ce programme
        local environments=$(./get_environments.sh "$program_id")

        for environment_id in $environments; do
            echo "Téléchargement des journaux pour l'environnement : $environment_id"

            # Télécharge les journaux via un script dédié
            ./download_logs.sh "$program_id" "$environment_id"
        done
    done
}

# Exécute les étapes
check_dependencies
download_logs_for_all_programs


