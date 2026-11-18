#!/usr/bin/env bash

# ==============================================================================
# Script      : import_crl_arl.sh
# Auteur      : TON_NOM
# Date        : 2026-04-16
# Version     : 1.1
#
# Objectif :
#   Renommer automatiquement les fichiers CRL/ARL présents dans /tmp
#   puis lancer leur import via :
#   /opt/sia/exploitation/crldp/import_manuel_crl.sh
# ==============================================================================

set -u

DIR="/tmp"
IMP="/opt/sia/exploitation/crldp/import_manuel_crl.sh"
LOG="/tmp/import_crl_arl_$(date +%Y%m%d_%H%M%S).log"

log() {
    local msg="$1"
    echo "$msg" | tee -a "$LOG"
}

log "=== Début import CRL/ARL : $(date) ==="

if [ ! -d "$DIR" ]; then
    log "[ERREUR] Répertoire introuvable : $DIR"
    exit 1
fi

if [ ! -f "$IMP" ]; then
    log "[ERREUR] Script d'import introuvable : $IMP"
    exit 1
fi

cd "$DIR" || {
    log "[ERREUR] Impossible d'accéder au répertoire : $DIR"
    exit 1
}

shopt -s nullglob
files=(AC_*.crl)
shopt -u nullglob

if [ ${#files[@]} -eq 0 ]; then
    log "[ERREUR] Aucun fichier AC_*.crl trouvé dans $DIR"
    exit 1
fi

for SRC in "${files[@]}"; do
    # Passage du nom en majuscules, extension conservée en .crl.
    UPPER_NAME=$(printf '%s' "$SRC" | tr '[:lower:]' '[:upper:]')
    BASE_NAME=${UPPER_NAME%.CRL}
    DST="${BASE_NAME}.crl"

    if [[ "$BASE_NAME" == AC_RACINE_* ]]; then
        DST="ARL_${DST}"
        TYPE="-a"
    else
        DST="CRL_${DST}"
        TYPE="-c"
    fi

    if [ ! -f "$SRC" ]; then
        log "[ERREUR] Fichier source absent : $SRC"
        continue
    fi

    if ! mv -f -- "$SRC" "$DST"; then
        log "[ERREUR] Renommage impossible : $SRC -> $DST"
        continue
    fi

    log "[OK] Renommage : $SRC -> $DST"

    if ! sh "$IMP" "$TYPE" -f "$DIR/$DST" >>"$LOG" 2>&1; then
        log "[ERREUR] Import échoué : $DIR/$DST"
        continue
    fi

    log "[OK] Import réussi : $DIR/$DST avec option $TYPE"
done

log "=== Fin import CRL/ARL : $(date) ==="
log "[INFO] Log disponible : $LOG"

exit 0
