#!/bin/bash
# ============================================================
# import_asset.sh
# Creates the Gazebo model folder structure for an external
# mesh file and generates template model.config + model.sdf.
#
# USAGE:
#   bash scripts/import_asset.sh MODEL_NAME MESH_FILE [SCALE]
#
# ARGUMENTS:
#   MODEL_NAME  Name for the model folder (no spaces — use underscores)
#   MESH_FILE   Path to the downloaded mesh file (.stl, .dae, or .obj)
#   SCALE       Optional uniform scale factor (default: 1)
#               Use 0.01 for cm→m, 0.001 for mm→m, 0.0254 for inches→m
#
# EXAMPLES:
#   bash scripts/import_asset.sh my_building ~/Downloads/building.stl
#   bash scripts/import_asset.sh my_car ~/Downloads/car.dae 0.01
#   bash scripts/import_asset.sh warehouse ~/Downloads/scene.obj 1
# ============================================================

PX4_MODELS="/home/az/PX4-Autopilot/Tools/simulation/gz/models"

MODEL_NAME=$1
MESH_FILE=$2
SCALE=${3:-1}

# ── Validate input ───────────────────────────────────────────
if [ -z "$MODEL_NAME" ] || [ -z "$MESH_FILE" ]; then
    echo ""
    echo "USAGE:"
    echo "  bash import_asset.sh MODEL_NAME MESH_FILE [SCALE]"
    echo ""
    echo "EXAMPLES:"
    echo "  bash import_asset.sh my_building ~/Downloads/building.stl"
    echo "  bash import_asset.sh my_car ~/Downloads/car.dae 0.01"
    echo "  bash import_asset.sh warehouse ~/Downloads/scene.obj 1"
    echo ""
    echo "SCALE values:"
    echo "  1        → model is already in meters"
    echo "  0.01     → model is in centimeters"
    echo "  0.001    → model is in millimeters"
    echo "  0.0254   → model is in inches"
    echo ""
    exit 1
fi

if [ ! -f "$MESH_FILE" ]; then
    echo "[ERROR] Mesh file not found: $MESH_FILE"
    exit 1
fi

# Detect file extension (lowercase)
EXT=$(echo "${MESH_FILE##*.}" | tr '[:upper:]' '[:lower:]')

if [[ "$EXT" != "stl" && "$EXT" != "dae" && "$EXT" != "obj" ]]; then
    echo "[ERROR] Unsupported format: .$EXT"
    echo "        Supported: .stl  .dae  .obj"
    echo "        For .fbx or other formats, convert to .dae using Blender first."
    exit 1
fi

DEST="$PX4_MODELS/$MODEL_NAME"
MESH_DEST="$DEST/meshes"
MESH_FILENAME=$(basename "$MESH_FILE")

echo ""
echo "============================================================"
echo "  Gazebo Mesh Importer — Session 04"
echo "============================================================"
echo "  Model name : $MODEL_NAME"
echo "  Source     : $MESH_FILE"
echo "  Format     : .$EXT"
echo "  Scale      : $SCALE $SCALE $SCALE"
echo "  Destination: $DEST"
echo "============================================================"
echo ""

# ── Create directory structure ───────────────────────────────
echo ">>> Creating model directory structure..."
mkdir -p "$MESH_DEST"

# ── Copy mesh file ───────────────────────────────────────────
echo ">>> Copying mesh file..."
cp "$MESH_FILE" "$MESH_DEST/$MESH_FILENAME"

# ── For .obj: also copy .mtl and textures ────────────────────
if [ "$EXT" = "obj" ]; then
    OBJ_DIR=$(dirname "$MESH_FILE")
    MTL_FILE="${MESH_FILE%.obj}.mtl"
    if [ -f "$MTL_FILE" ]; then
        echo ">>> Copying .mtl file..."
        cp "$MTL_FILE" "$MESH_DEST/$(basename "$MTL_FILE")"
    fi

    # Look for common texture directories and copy contents alongside mesh
    for TEX_DIR in "$OBJ_DIR/textures" "$OBJ_DIR/Textures" "$OBJ_DIR/materials/textures"; do
        if [ -d "$TEX_DIR" ]; then
            echo ">>> Copying textures from $TEX_DIR..."
            cp "$TEX_DIR"/*.png "$MESH_DEST/" 2>/dev/null
            cp "$TEX_DIR"/*.jpg "$MESH_DEST/" 2>/dev/null
            cp "$TEX_DIR"/*.jpeg "$MESH_DEST/" 2>/dev/null
        fi
    done

    # Also copy any loose image files from the same directory as the .obj
    echo ">>> Copying any loose texture files alongside .obj..."
    cp "$OBJ_DIR"/*.png "$MESH_DEST/" 2>/dev/null
    cp "$OBJ_DIR"/*.jpg "$MESH_DEST/" 2>/dev/null
fi

# ── For .dae: also copy textures ─────────────────────────────
if [ "$EXT" = "dae" ]; then
    DAE_DIR=$(dirname "$MESH_FILE")
    for TEX_DIR in "$DAE_DIR/textures" "$DAE_DIR/Textures" "$DAE_DIR/images"; do
        if [ -d "$TEX_DIR" ]; then
            echo ">>> Copying textures from $TEX_DIR..."
            cp "$TEX_DIR"/*.png "$MESH_DEST/" 2>/dev/null
            cp "$TEX_DIR"/*.jpg "$MESH_DEST/" 2>/dev/null
        fi
    done
fi

# ── Generate model.config ────────────────────────────────────
echo ">>> Generating model.config..."
cat > "$DEST/model.config" << EOF
<?xml version="1.0"?>
<model>
  <name>$MODEL_NAME</name>
  <version>1.0</version>
  <sdf version="1.10">model.sdf</sdf>
  <description>Imported $EXT model — Session 04</description>
</model>
EOF

# ── Generate model.sdf ───────────────────────────────────────
echo ">>> Generating model.sdf..."

# STL: add a grey material since STL has no color info
if [ "$EXT" = "stl" ]; then
    cat > "$DEST/model.sdf" << EOF
<?xml version="1.0" ?>
<sdf version="1.10">
  <model name="$MODEL_NAME">
    <static>true</static>
    <link name="link">

      <!-- Visual: full mesh (STL has no color — material set manually) -->
      <visual name="visual">
        <geometry>
          <mesh>
            <uri>model://$MODEL_NAME/meshes/$MESH_FILENAME</uri>
            <scale>$SCALE $SCALE $SCALE</scale>
          </mesh>
        </geometry>
        <material>
          <!-- STL has no built-in color; edit these values as needed -->
          <ambient>0.6 0.6 0.6 1</ambient>
          <diffuse>0.6 0.6 0.6 1</diffuse>
          <specular>0.2 0.2 0.2 1</specular>
        </material>
      </visual>

      <!-- Collision: replace box size with actual bounding dimensions -->
      <collision name="collision">
        <geometry>
          <box><size>1 1 1</size></box>
        </geometry>
      </collision>

    </link>
  </model>
</sdf>
EOF

else
    # DAE / OBJ: materials and textures come from the mesh file itself
    cat > "$DEST/model.sdf" << EOF
<?xml version="1.0" ?>
<sdf version="1.10">
  <model name="$MODEL_NAME">
    <static>true</static>
    <link name="link">

      <!-- Visual: full mesh — materials/textures from the mesh file -->
      <visual name="visual">
        <geometry>
          <mesh>
            <uri>model://$MODEL_NAME/meshes/$MESH_FILENAME</uri>
            <scale>$SCALE $SCALE $SCALE</scale>
          </mesh>
        </geometry>
      </visual>

      <!-- Collision: replace box size with actual bounding dimensions -->
      <collision name="collision">
        <geometry>
          <box><size>1 1 1</size></box>
        </geometry>
      </collision>

    </link>
  </model>
</sdf>
EOF
fi

# ── Verify result ────────────────────────────────────────────
echo ""
echo ">>> Files created:"
find "$DEST" -type f | sort | sed "s|$PX4_MODELS/||"
echo ""

# Check for potential texture issues in .obj/.mtl
if [ "$EXT" = "obj" ] && [ -f "$MESH_DEST/$(basename "$MTL_FILE" 2>/dev/null)" ]; then
    echo ">>> Checking texture references in .mtl..."
    MTL_TEXTURES=$(grep "map_" "$MESH_DEST/$(basename "$MTL_FILE")" | awk '{print $2}' | grep -v "^http")
    for TEX in $MTL_TEXTURES; do
        TEX_NAME=$(basename "$TEX")
        if [ ! -f "$MESH_DEST/$TEX_NAME" ]; then
            echo "[WARNING] Texture referenced in .mtl but not found in meshes/: $TEX_NAME"
            echo "          Copy or symlink it into: $MESH_DEST/"
        fi
    done
fi

echo "============================================================"
echo "  NEXT STEPS:"
echo ""
echo "  1. Open $DEST/model.sdf"
echo "     → Update the <collision> box size to match your model"
echo "     → Adjust <scale> if the model is wrong size in Gazebo"
echo ""
echo "  2. Add to a world SDF:"
echo "    <include>"
echo "      <uri>model://$MODEL_NAME</uri>"
echo "      <name>${MODEL_NAME}_1</name>"
echo "      <pose>15 0 0 0 0 0</pose>"
echo "    </include>"
echo ""
echo "  3. Launch:"
echo "    export GZ_SIM_RESOURCE_PATH=$PX4_MODELS"
echo "    export GZ_SIM_SERVER_CONFIG_PATH=~/.simulation-gazebo/server.config"
echo "    gz sim -r /path/to/your_world.sdf"
echo ""
echo "  4. If model is wrong size, run first then check:"
echo "    gz model -m ${MODEL_NAME}_1 --pose"
echo "    Then adjust <scale> in model.sdf"
echo "============================================================"
echo ""
