#!/usr/bin/env bash
#
# Run the license plate recognition pipeline end to end.
#
#   ./run.sh                  # all three stages
#   ./run.sh ocr              # detect + track + OCR  -> Output/detections.csv
#   ./run.sh interpolate      # fill gaps             -> Output/detections_interpolated.csv
#   ./run.sh display          # draw overlays         -> Output/out.mp4
#
#   MAX_FRAMES=90 ./run.sh    # only process the first 90 frames (quick test run)
#
set -euo pipefail

cd "$(dirname "$0")"

PYTHON="./venv/bin/python"
if [ ! -x "$PYTHON" ]; then
    echo "No virtualenv at ./venv - falling back to python3 on PATH" >&2
    PYTHON="$(command -v python3)"
fi

# 'from sort.sort import *' needs the repo root importable
export PYTHONPATH="$PWD${PYTHONPATH:+:$PYTHONPATH}"

mkdir -p Output

# Extract the code cells of a notebook and pipe them to python.
# Jupyter magics (%matplotlib inline etc.) and shell escapes are dropped.
run_notebook() {
    local notebook="$1"
    echo "=== $notebook ==="
    "$PYTHON" - "$notebook" <<'PYEOF' | "$PYTHON" -
import json, sys

cells = json.load(open(sys.argv[1]))["cells"]
for cell in cells:
    if cell["cell_type"] != "code":
        continue
    for line in cell["source"]:
        if line.lstrip().startswith(("%", "!")):
            continue
        sys.stdout.write(line)
    sys.stdout.write("\n")
PYEOF
}

stage="${1:-all}"

case "$stage" in
    ocr)
        run_notebook OCR.ipynb
        ;;
    interpolate)
        run_notebook utils.ipynb
        ;;
    display)
        run_notebook DetectionsAndDisplay.ipynb
        ;;
    all)
        run_notebook OCR.ipynb
        run_notebook utils.ipynb
        run_notebook DetectionsAndDisplay.ipynb
        ;;
    *)
        echo "usage: $0 [ocr|interpolate|display|all]" >&2
        exit 1
        ;;
esac

echo "done"
