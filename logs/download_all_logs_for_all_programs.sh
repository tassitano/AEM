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

# Obtenir la liste des programmes et extraire uniquement les IDs
programs=$(../program/list_programs.sh | jq -r '.[] | .id')
if [[ -z "$programs" ]]; then
  echo "Erreur : Impossible de récupérer la liste des programmes."
  exit 1
fi

# Parcourir chaque programme
for program_id in $programs; do
  echo "Traitement du programme ID : $program_id"

  # Obtenir la liste des environnements associés au programme
  environments=$(../environments/list_environments.sh "$program_id" | jq -r '.[] | .id')
  if [[ -z "$environments" ]]; then
    echo "Erreur : Impossible de récupérer les environnements pour le programme $program_id."
    continue
  fi

  # Parcourir chaque environnement
  for environment_id in $environments; do
    echo "Téléchargement des journaux pour l'environnement ID : $environment_id"

    # Télécharger les journaux pour cet environnement
    ../logs/download_logs.sh "$program_id" "$environment_id"
    if [[ $? -ne 0 ]]; then
      echo "Erreur : Échec du téléchargement des journaux pour l'environnement $environment_id."
    fi
  done
done

echo "Téléchargement des journaux terminé."
