#!/bin/bash

# ----------------------------------------------------------------------
# Script : download_all_logs_for_program.sh
#
# Description :
# Ce script télécharge tous les journaux pour un programme spécifique
# d'Adobe Cloud Manager. Si aucun ID de programme n'est fourni, il affiche
# une liste des programmes disponibles et demande à l'utilisateur de
# saisir un ID.
#
# ----------------------------------------------------------------------

# Charger les variables communes
source ../common/common.sh

# Fonction pour afficher la liste des programmes disponibles
list_programs() {
  programs_json=$(../program/list_programs.sh)
  if [[ -z "$programs_json" ]]; then
    echo "Erreur : Impossible de récupérer la liste des programmes."
    exit 1
  fi

  echo "Liste des programmes disponibles :"
  echo "$programs_json" | jq -r '._embedded.programs[] | "ID: \(.id) - Nom: \(.name)"'
}

# Vérifier si un ID de programme a été passé en paramètre
if [[ -z "$1" ]]; then
  echo "Aucun ID de programme fourni."
  list_programs
  echo -n "Veuillez saisir l'ID du programme désiré : "
  read -r program_id
else
  program_id="$1"
fi

# Vérifier si l'ID du programme est valide
if [[ -z "$program_id" ]]; then
  echo "Erreur : Aucun ID de programme valide fourni."
  exit 1
fi

# Obtenir les environnements pour le programme donné
environments_json=$(../environments/list_environments.sh "$program_id")
if [[ -z "$environments_json" ]]; then
  echo "Erreur : Impossible de récupérer les environnements pour le programme ID $program_id."
  exit 1
fi

# Extraire les environnements et leurs journaux
environments=$(echo "$environments_json" | jq -r '._embedded.environments[] | "\(.id) \(.name)"')
if [[ -z "$environments" ]]; then
  echo "Aucun environnement trouvé pour le programme ID $program_id."
  exit 1
fi

# Télécharger les journaux pour chaque environnement
while IFS= read -r environment; do
  environment_id=$(echo "$environment" | awk '{print $1}')
  environment_name=$(echo "$environment" | awk '{for (i=2; i<=NF; i++) printf "%s ", $i; print ""}')
  echo "Téléchargement des journaux pour l'environnement : $environment_name (ID : $environment_id)"
  ../logs/download_logs.sh "$program_id" "$environment_id"
done <<< "$environments"

echo "Téléchargement des journaux terminé."
