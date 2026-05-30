#!/bin/bash
# ============================================================
# download_fuel.sh
# Helper script to download a model or world from Gazebo Fuel
# and copy it to the correct PX4 directory.
#
# USAGE:
#   Model: bash scripts/download_fuel.sh model OpenRobotics Ambulance
#   Model: bash scripts/download_fuel.sh model OpenRobotics "Construction Cone"
#   World: bash scripts/download_fuel.sh world OpenRobotics Depot
#
# NOTE: Quote model names that contain spaces.
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
    echo "  bash download_fuel.sh model OpenRobotics \"Construction Cone\""
    echo "  bash download_fuel.sh world OpenRobotics Depot"
    echo ""
    echo "NOTE: Quote model names that contain spaces."
    echo ""
    exit 1
fi

OWNER_LOWER=$(echo "$OWNER" | tr '[:upper:]' '[:lower:]')
NAME_LOWER=$(echo "$NAME" | tr '[:upper:]' '[:lower:]')
NAME_SAFE=$(echo "$NAME" | tr ' ' '_')   # spaces → underscores for the destination folder
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
# Fuel stores names lowercase in the cache; version number is not always 1
ASSET_DIR="$FUEL_CACHE/${OWNER_LOWER}/${TYPE}s/${NAME_LOWER}"
if [ ! -d "$ASSET_DIR" ]; then
    echo "[ERROR] Asset not found in cache: $ASSET_DIR"
    echo "        Check: ls $FUEL_CACHE/${OWNER_LOWER}/${TYPE}s/"
    exit 1
fi
VERSION=$(ls "$ASSET_DIR" 2>/dev/null | grep -E '^[0-9]+$' | sort -n | tail -1)
if [ -z "$VERSION" ]; then
    echo "[ERROR] No version folder found in: $ASSET_DIR"
    echo "        Contents: $(ls "$ASSET_DIR")"
    exit 1
fi
CACHE_PATH="$ASSET_DIR/${VERSION}"
echo ">>> Detected version: $VERSION"

# ── Step 3: Copy to PX4 directory ────────────────────────────
if [ "$TYPE" = "model" ]; then
    DEST="$PX4_DIR/models/$NAME_SAFE"
    echo ">>> Copying to PX4 models directory..."
    echo "    From: $CACHE_PATH"
    echo "    To:   $DEST"
    mkdir -p "$DEST"
    cp -r "$CACHE_PATH/." "$DEST/"

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
    ls "$PX4_DIR/models/$NAME_SAFE/"
    echo ""
    if [ ! -f "$PX4_DIR/models/$NAME_SAFE/model.config" ]; then
        echo "[WARNING] model.config not found — Gazebo may not load this model"
    fi
    if [ ! -f "$PX4_DIR/models/$NAME_SAFE/model.sdf" ]; then
        echo "[WARNING] model.sdf not found — check the folder contents"
    fi
fi

WORLD_NAME="${SDF_NAME%.sdf}"   # strip .sdf extension for PX4_GZ_WORLD

echo "============================================================"
echo "  NEXT STEPS:"
echo ""
if [ "$TYPE" = "model" ]; then
    echo "  1. Add to your world SDF:"
    echo "    <include>"
    echo "      <uri>model://$NAME_SAFE</uri>"
    echo "      <name>${NAME_SAFE}_1</name>"
    echo "      <pose>10 0 0 0 0 0</pose>"
    echo "    </include>"
    echo ""
    echo "  2. Launch (Terminal 1):"
    echo "    export GZ_SIM_RESOURCE_PATH=$PX4_DIR/models"
    echo "    export GZ_SIM_SERVER_CONFIG_PATH=~/.simulation-gazebo/server.config"
    echo "    export GZ_SIM_SYSTEM_PLUGIN_PATH=~/PX4-Autopilot/build/px4_sitl_default/src/modules/simulation/gz_plugins"
    echo "    gz sim -r /path/to/your_world.sdf"
    echo ""
    echo "  3. Connect PX4 (Terminal 2, after Gazebo is running):"
    echo "    cd ~/PX4-Autopilot"
    echo "    PX4_GZ_STANDALONE=1 PX4_GZ_WORLD=YOUR_WORLD_NAME make px4_sitl gz_x500"
    echo "    (replace YOUR_WORLD_NAME with the <world name='...'> value in your SDF)"
elif [ "$TYPE" = "world" ]; then
    echo "  NOTE: Downloaded Fuel worlds usually need PX4 compatibility fixes."
    echo "  See the 'Making Any Gazebo World Work with PX4' section in README.md."
    echo ""
    echo "  After applying fixes, launch:"
    echo ""
    echo "  Terminal 1:"
    echo "    export GZ_SIM_RESOURCE_PATH=$PX4_DIR/models"
    echo "    export GZ_SIM_SERVER_CONFIG_PATH=~/.simulation-gazebo/server.config"
    echo "    export GZ_SIM_SYSTEM_PLUGIN_PATH=~/PX4-Autopilot/build/px4_sitl_default/src/modules/simulation/gz_plugins"
    echo "    gz sim -r $PX4_DIR/worlds/$SDF_NAME"
    echo ""
    echo "  Terminal 2 (after Gazebo is running):"
    echo "    cd ~/PX4-Autopilot"
    echo "    PX4_GZ_STANDALONE=1 PX4_GZ_WORLD=$WORLD_NAME make px4_sitl gz_x500"
fi
echo "============================================================"
echo ""
