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
source ../common/common.sh

# Obtenir la liste des programmes
programs_json=$(../program/list_programs.sh)
if [[ -z "$programs_json" ]]; then
  echo "Erreur : Impossible de récupérer la liste des programmes."
  exit 1
fi

# Extraire les ID et noms des programmes du JSON
programs=$(echo "$programs_json" | jq -r '._embedded.programs[] | "\(.id) \(.name)"')
if [[ -z "$programs" ]]; then
  echo "Erreur : Aucun programme trouvé dans la réponse JSON."
  exit 1
fi

# Parcourir chaque programme
while IFS= read -r program; do
  program_id=$(echo "$program" | awk '{print $1}')
  program_name=$(echo "$program" | awk '{for (i=2; i<=NF; i++) printf "%s ", $i; print ""}')
  echo "Traitement du programme : $program_name (ID : $program_id)"

  # Obtenir la liste des environnements associés au programme
  environments_json=$(../environments/list_environments.sh "$program_id")
  if [[ -z "$environments_json" ]]; then
    echo "Erreur : Impossible de récupérer la liste des environnements pour le programme $program_name."
    continue
  fi

  environments=$(echo "$environments_json" | jq -r '._embedded.environments[] | "\(.id) \(.name)"')

  if [[ -z "$environments" ]]; then
    echo "Aucun environnement trouvé pour le programme $program_name."
    continue
  fi

  # Parcourir chaque environnement
  while IFS= read -r environment; do
    environment_id=$(echo "$environment" | awk '{print $1}')
    environment_name=$(echo "$environment" | awk '{for (i=2; i<=NF; i++) printf "%s ", $i; print ""}')
    echo "Téléchargement des journaux pour l'environnement : $environment_name (ID : $environment_id)"
    ../logs/download_logs.sh "$program_id" "$environment_id"
  done <<< "$environments"

done <<< "$programs"

echo "Téléchargement des journaux terminé."
