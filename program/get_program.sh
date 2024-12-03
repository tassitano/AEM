#!/bin/bash
source ../common/common.sh

# Script pour afficher les détails d'un programme Adobe Cloud Manager et ses environnements associés.
# Ce script récupère la liste des programmes, permet à l'utilisateur de sélectionner un programme
# par son ID, puis affiche les informations détaillées du programme sélectionné et la liste des
# environnements associés (incluant l'ID, le nom, le type et le statut de chaque environnement).

# Usage :
# ./script_name.sh
# Exemple d'exécution :
# ./adobe-api-init.sh
# (Le script affichera les programmes disponibles et demandera un ID de programme pour afficher ses détails.)

# Fonction pour afficher les détails d'un programme et ses environnements associés
display_program_and_environments() {
    local program_id=$1

    # Afficher les détails du programme sélectionné
    program_details=$(echo "$output" | jq -r --arg id "$program_id" '._embedded.programs[] | select(.id == $id)')
    
    if [[ -n "$program_details" ]]; then
        echo "Détails du programme sélectionné :"
        echo "$program_details" | jq .

        # Récupérer les environnements associés au programme sélectionné
        environments=$(../environments/list_environments.sh "$program_id")
        
        if echo "$environments" | jq -e '._embedded.environments' >/dev/null 2>&1; then
            echo "Environnements associés au programme $program_id :"
            echo "$environments" | jq -r '._embedded.environments[] | "id=\(.id), name=\(.name), type=\(.type), status=\(.status)"'
        else
            echo "Aucun environnement trouvé pour le programme avec l'id $program_id."
        fi
    else
        echo "Aucun programme trouvé avec l'id $program_id."
    fi
}

# Appeler list_programs.sh et capturer la sortie JSON
output=$(./list_programs.sh)

# Vérifier que la sortie est du JSON valide
if [[ -z "$output" || ! ($output == \{* || $output == \[* ) ]]; then
    echo "Erreur : La sortie de list_programs.sh n'est pas du JSON valide ou est vide."
    echo "Sortie reçue : $output"
    exit 1
fi

# Afficher la liste des programmes et demander à l'utilisateur de sélectionner un programme par son id
echo "Liste des programmes :"
echo "$output" | jq -r '._embedded.programs[] | "id=\(.id), name=\(.name), status=\(.status)"'

# Demander à l'utilisateur de sélectionner un programme par son id
read -p "Entrez l'id du programme pour lequel vous souhaitez obtenir le détail : " program_id

# Afficher les détails du programme et les environnements associés
display_program_and_environments "$program_id"
