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

# Extraire les ID des programmes du JSON
programs=$(echo "$programs_json" | jq -r '._embedded.programs[] | .id')
if [[ -z "$programs" ]]; then
  echo "Erreur : Aucun ID de programme trouvé dans la réponse JSON."
  exit 1
fi

# Parcourir chaque programme
for program_id in $programs; do
  echo "Traitement du programme ID : $program_id"

  # Obtenir la liste des environnements associés au programme
  environments=$(../environments/list_environments.sh "$program_id" | jq -r '._embedded.environments[] | .id')
  if [[ -z "$environments" ]]; then
    echo "Erreur : Impossible de récupérer la liste des environnements pour le programme $program_id."
    continue
  fi

  # Parcourir chaque environnement
  for environment_id in $environments; do
    echo "Téléchargement des journaux pour l'environnement ID : $environment_id"
    ../logs/download_logs.sh "$program_id" "$environment_id"
  done
done

echo "Téléchargement des journaux terminé."
