#!/bin/bash

# Fonction pour vérifier si Adobe I/O CLI est installé
function check_aio_installed() {
    if ! command -v aio &> /dev/null; then
        echo "Adobe I/O CLI (aio) n'est pas installé. Veuillez l'installer avant de continuer."
        exit 1
    fi
}

# Fonction pour afficher la liste des programmes
function list_programs() {
    echo "Récupération des programmes disponibles..."
    PROGRAMS=$(aio cloudmanager program:list --json | jq -r '.content[] | "\(.id) - \(.name)"')
    echo "$PROGRAMS"
}

# Fonction pour afficher la liste des environnements pour un programme
function list_environments() {
    local program_id=$1
    echo "Récupération des environnements disponibles pour le programme ID: $program_id..."
    ENVIRONMENTS=$(aio cloudmanager environment:list --program-id "$program_id" --json | jq -r '.content[] | "\(.id) - \(.name)"')
    echo "$ENVIRONMENTS"
}

# Fonction pour demander à l'utilisateur de choisir un programme et un environnement
function select_program_and_environment() {
    list_programs
    echo "Entrez le numéro du programme souhaité :"
    read PROGRAM_CHOICE
    PROGRAM_ID=$(echo "$PROGRAMS" | sed -n "${PROGRAM_CHOICE}p" | cut -d ' ' -f1)
    
    # Récupérer les environnements pour ce programme
    list_environments "$PROGRAM_ID"
    echo "Entrez le numéro de l'environnement souhaité :"
    read ENVIRONMENT_CHOICE
    ENVIRONMENT_ID=$(echo "$ENVIRONMENTS" | sed -n "${ENVIRONMENT_CHOICE}p" | cut -d ' ' -f1)
    
    echo "Programme sélectionné : $PROGRAM_ID, Environnement sélectionné : $ENVIRONMENT_ID"
}

# Fonction pour vérifier si un paramètre est vide
function check_empty() {
    local var=$1
    if [ -z "$var" ]; then
        echo "Le paramètre est vide. Veuillez fournir une valeur."
        exit 1
    fi
}
