#!/bin/bash
# Hand the dotapicker_model DB credential to websurfinmurf (needs sudo; their ~/secrets is mode 700).
set -euo pipefail
SRC=/home/administrator/projects/secrets/dotapicker-model-db.env
sudo install -o websurfinmurf -g websurfinmurf -m 600 "$SRC" /home/websurfinmurf/secrets/dotapicker-model-db.env
sudo ls -l /home/websurfinmurf/secrets/dotapicker-model-db.env
