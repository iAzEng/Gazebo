#!/bin/bash
# ============================================================
# download_fuel.sh
# Helper script to download a model or world from Gazebo Fuel
# and copy it to the correct PX4 directory.
#
# USAGE:
#   Model: bash scripts/download_fuel.sh model OpenRobotics Ambulance
#   World: bash scripts/download_fuel.sh world OpenRobotics Depot
# ============================================================

PX4_DIR="/home/az/PX4-Autopilot/Tools/simulation/gz"
FUEL_CACHE="$HOME/.gz/fuel/fuel.gazebosim.org"

TYPE=$1       # "model" or "world"
OWNER=$2      # e.g. "OpenRobotics"
NAME=$3       # e.g. "Ambulance"

# ── Validate input ───────────────────────────────────────────
if [ -z "$TYPE" ] || [ -z "$OWNER" ] || [ -z "$NAME" ]; then
    echo ""
    echo "USAGE:"
    echo "  bash download_fuel.sh model OWNER NAME"
    echo "  bash download_fuel.sh world OWNER NAME"
    echo ""
    echo "EXAMPLES:"
    echo "  bash download_fuel.sh model OpenRobotics Ambulance"
    echo "  bash download_fuel.sh world OpenRobotics Depot"
    echo ""
    exit 1
fi

OWNER_LOWER=$(echo "$OWNER" | tr '[:upper:]' '[:lower:]')
URL="https://fuel.gazebosim.org/1.0/${OWNER}/${TYPE}s/${NAME}"

echo ""
echo "============================================================"
echo "  Gazebo Fuel Downloader — Session 03"
echo "============================================================"
echo "  Type  : $TYPE"
echo "  Owner : $OWNER"
echo "  Name  : $NAME"
echo "  URL   : $URL"
echo "============================================================"
echo ""

# ── Step 1: Download from Fuel ───────────────────────────────
echo ">>> Downloading from Gazebo Fuel..."
gz fuel download -u "$URL" -v 4
if [ $? -ne 0 ]; then
    echo ""
    echo "[ERROR] Download failed. Check:"
    echo "  - Internet connection"
    echo "  - URL is correct: $URL"
    echo "  - gz fuel tools installed: gz fuel -h"
    exit 1
fi
echo ""

# ── Step 2: Locate the downloaded asset ──────────────────────
CACHE_PATH="$FUEL_CACHE/${OWNER_LOWER}/${TYPE}s/${NAME}/1"
if [ ! -d "$CACHE_PATH" ]; then
    echo "[ERROR] Expected cache path not found: $CACHE_PATH"
    echo "        Check: ls $FUEL_CACHE/${OWNER_LOWER}/${TYPE}s/"
    exit 1
fi

# ── Step 3: Copy to PX4 directory ────────────────────────────
if [ "$TYPE" = "model" ]; then
    DEST="$PX4_DIR/models/$NAME"
    echo ">>> Copying to PX4 models directory..."
    echo "    From: $CACHE_PATH"
    echo "    To:   $DEST"
    cp -r "$CACHE_PATH" "$DEST"

elif [ "$TYPE" = "world" ]; then
    # Find the .sdf file inside the world folder
    SDF_FILE=$(find "$CACHE_PATH" -maxdepth 1 -name "*.sdf" | head -1)
    if [ -z "$SDF_FILE" ]; then
        echo "[ERROR] No .sdf file found in $CACHE_PATH"
        exit 1
    fi
    SDF_NAME=$(basename "$SDF_FILE")
    DEST="$PX4_DIR/worlds/$SDF_NAME"
    echo ">>> Copying world SDF to PX4 worlds directory..."
    echo "    From: $SDF_FILE"
    echo "    To:   $DEST"
    cp "$SDF_FILE" "$DEST"
fi

echo ""
echo ">>> Done!"
echo ""

# ── Step 4: Verify ───────────────────────────────────────────
if [ "$TYPE" = "model" ]; then
    echo ">>> Verifying model structure:"
    ls "$PX4_DIR/models/$NAME/"
    echo ""
    if [ ! -f "$PX4_DIR/models/$NAME/model.config" ]; then
        echo "[WARNING] model.config not found — Gazebo may not load this model"
    fi
    if [ ! -f "$PX4_DIR/models/$NAME/model.sdf" ]; then
        echo "[WARNING] model.sdf not found — check the folder contents"
    fi
fi

echo "============================================================"
echo "  NEXT STEPS:"
echo ""
if [ "$TYPE" = "model" ]; then
    echo "  Add to your world SDF:"
    echo "    <include>"
    echo "      <uri>model://$NAME</uri>"
    echo "      <name>${NAME}_1</name>"
    echo "      <pose>10 0 0 0 0 0</pose>"
    echo "    </include>"
    echo ""
    echo "  Run with:"
    echo "    export GZ_SIM_RESOURCE_PATH=$PX4_DIR/models"
    echo "    gz sim /path/to/your_world.sdf"
elif [ "$TYPE" = "world" ]; then
    echo "  Run with:"
    echo "    export GZ_SIM_RESOURCE_PATH=$PX4_DIR/models"
    echo "    gz sim $PX4_DIR/worlds/$SDF_NAME"
fi
echo "============================================================"
echo ""
