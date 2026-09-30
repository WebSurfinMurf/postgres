#!/bin/bash
# Nightly logical dump (pg_dump custom format) of selected databases, 14-day local retention.
# Output lives under projects/backups/pgdumps, which the 04:00 restic job snapshots (7d/5w/6m).
# Usage: dump-logical.sh [db ...]   (default: dotapicker_model)
set -euo pipefail
DBS=("${@:-dotapicker_model}")
OUT="${PGDUMP_DIR:-$HOME/projects/backups/pgdumps}"
mkdir -p "$OUT"; chmod 700 "$OUT"
TS=$(date +%Y%m%d-%H%M%S)
for db in "${DBS[@]}"; do
  f="$OUT/${db}_${TS}.dump"
  docker exec postgres sh -c 'pg_dump -U "$POSTGRES_USER" -Fc "$0"' "$db" > "$f.tmp"
  docker exec -i postgres pg_restore -l < "$f.tmp" >/dev/null   # verify archive is readable
  mv "$f.tmp" "$f"; chmod 600 "$f"
  find "$OUT" -name "${db}_*.dump" -mtime +14 -delete
  echo "ok $f"
done
