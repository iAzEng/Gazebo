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
#   MESH_FILE   Path to the downloaded mesh file (.stl .dae .obj .glb .gltf)
#   SCALE       Optional uniform scale factor (default: 1)
#               Use 0.01 for cm→m, 0.001 for mm→m, 0.0254 for inches→m
#
# EXAMPLES:
#   bash scripts/import_asset.sh my_building ~/Downloads/building.stl
#   bash scripts/import_asset.sh my_car ~/Downloads/car.dae 0.01
#   bash scripts/import_asset.sh warehouse ~/Downloads/scene.obj 1
#   bash scripts/import_asset.sh my_model ~/Downloads/folder/model.glb 1
# ============================================================

PX4_MODELS="$HOME/PX4-Autopilot/Tools/simulation/gz/models"

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
    echo "  bash import_asset.sh cartoon_car ~/Downloads/model.glb 1"
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

if [[ "$EXT" != "stl" && "$EXT" != "dae" && "$EXT" != "obj" && "$EXT" != "glb" && "$EXT" != "gltf" ]]; then
    echo "[ERROR] Unsupported format: .$EXT"
    echo "        Supported: .stl  .dae  .obj  .glb  .gltf"
    echo "        For .fbx: convert to .glb using Blender (File → Export → glTF 2.0)"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ORIG_EXT="$EXT"   # remember original format before possible conversion

# ── Auto-convert .obj and .dae to .glb ───────────────────────
# Gazebo Harmonic has a buggy COLLADA loader (crash) and OBJ loader (white model).
# Converting to GLB first is the most reliable workflow.
if [ "$EXT" = "obj" ] || [ "$EXT" = "dae" ]; then
    echo ""
    echo ">>> .$EXT detected — will convert to .glb for reliable Gazebo loading."
    echo ""
    echo "  Sketchfab downloads usually look like:"
    echo "    download-folder/"
    echo "    ├── source/"
    echo "    │   └── $(basename "$MESH_FILE")"
    echo "    └── textures/"
    echo "        └── *.png / *.jpg"
    echo ""
    read -p "  Enter the root download folder (parent of textures/): " BASE_DIR
    BASE_DIR="${BASE_DIR/#\~/$HOME}"   # expand ~ if typed

    CONVERTED_GLB="${MESH_FILE%.*}.glb"
    echo ""
    echo ">>> Converting .$EXT → .glb..."
    python3 "$SCRIPT_DIR/convert_to_glb.py" "$MESH_FILE" "$CONVERTED_GLB" --base-dir "$BASE_DIR"
    if [ $? -eq 0 ] && [ -f "$CONVERTED_GLB" ]; then
        echo ">>> Conversion successful — using GLB for model folder."
        MESH_FILE="$CONVERTED_GLB"
        EXT="glb"
    else
        echo "[WARNING] Conversion failed — falling back to original .$EXT"
        echo "          Set GZ_MESH_FORCE_ASSIMP=1 when launching Gazebo."
    fi
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

# ── For .dae: strip TANGENT/BINORMAL inputs (crash Gazebo's COLLADA loader) ──
if [ "$EXT" = "dae" ]; then
    python3 - "$MESH_DEST/$MESH_FILENAME" << 'PYEOF'
import sys, xml.etree.ElementTree as ET
path = sys.argv[1]
ET.register_namespace('', 'http://www.collada.org/2005/11/COLLADASchema')
tree = ET.parse(path)
root = tree.getroot()
ns = 'http://www.collada.org/2005/11/COLLADASchema'
removed = 0
for pl in root.iter(f'{{{ns}}}polylist'):
    for inp in pl.findall(f'{{{ns}}}input'):
        if inp.get('semantic') in ('TANGENT', 'BINORMAL'):
            pl.remove(inp)
            removed += 1
if removed:
    tree.write(path, encoding='unicode', xml_declaration=True)
    print(f"    Removed {removed} TANGENT/BINORMAL input(s) — Gazebo COLLADA compatibility fix applied.")
PYEOF
fi

# ── For .obj: also copy .mtl and textures ────────────────────
if [ "$EXT" = "obj" ]; then
    OBJ_DIR=$(dirname "$MESH_FILE")
    MTL_FILE="${MESH_FILE%.obj}.mtl"
    if [ -f "$MTL_FILE" ]; then
        echo ">>> Copying .mtl file..."
        cp "$MTL_FILE" "$MESH_DEST/$(basename "$MTL_FILE")"
    fi

    for TEX_DIR in "$OBJ_DIR/textures" "$OBJ_DIR/Textures" "$OBJ_DIR/materials/textures"; do
        if [ -d "$TEX_DIR" ]; then
            echo ">>> Copying textures from $TEX_DIR..."
            cp "$TEX_DIR"/*.png "$MESH_DEST/" 2>/dev/null
            cp "$TEX_DIR"/*.jpg "$MESH_DEST/" 2>/dev/null
            cp "$TEX_DIR"/*.jpeg "$MESH_DEST/" 2>/dev/null
        fi
    done

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
            cp "$TEX_DIR"/*.jpeg "$MESH_DEST/" 2>/dev/null
        fi
    done
fi

# ── GLB: all textures are embedded — no extra files needed ───
if [ "$EXT" = "glb" ]; then
    echo ">>> GLB format: textures are embedded in the file — no extra copies needed."
fi

# ── GLTF: multi-file format — copy .bin and textures/ alongside the .gltf ──
if [ "$EXT" = "gltf" ]; then
    GLTF_DIR=$(dirname "$MESH_FILE")
    # Copy companion .bin file (same name as .gltf, different extension)
    BIN_FILE="${MESH_FILE%.gltf}.bin"
    if [ -f "$BIN_FILE" ]; then
        echo ">>> Copying companion .bin file..."
        cp "$BIN_FILE" "$MESH_DEST/$(basename "$BIN_FILE")"
    else
        echo "[WARNING] No .bin file found alongside the .gltf — model may not load correctly."
        echo "          Expected: $BIN_FILE"
    fi
    # Copy textures/ folder — GLTF references textures relative to itself
    if [ -d "$GLTF_DIR/textures" ]; then
        echo ">>> Copying textures/ folder..."
        cp -r "$GLTF_DIR/textures" "$MESH_DEST/textures"
    else
        echo "[WARNING] No textures/ folder found — model will load without textures."
    fi
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

elif [ "$EXT" = "glb" ] || [ "$EXT" = "gltf" ]; then
    # Use 0.1 scale for converted models (OBJ/DAE → GLB); keep user scale for native GLB/GLTF
    GLB_SCALE="$SCALE"
    if [ "$ORIG_EXT" = "obj" ] || [ "$ORIG_EXT" = "dae" ]; then
        GLB_SCALE="0.1"
    fi
    cat > "$DEST/model.sdf" << EOF
<?xml version="1.0" ?>
<sdf version="1.10">
  <model name="$MODEL_NAME">
    <static>true</static>
    <link name="link">

      <!-- glTF/GLB uses Y-up; Gazebo uses Z-up — rotate 90° around X -->
      <pose>0 0 0 1.5708 0 0</pose>

      <!-- Visual: textures embedded (GLB) or in meshes/textures/ (GLTF) -->
      <visual name="visual">
        <geometry>
          <mesh>
            <uri>model://$MODEL_NAME/meshes/$MESH_FILENAME</uri>
            <scale>$GLB_SCALE $GLB_SCALE $GLB_SCALE</scale>
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

else
    # DAE / OBJ: materials and textures come from the mesh file itself
    cat > "$DEST/model.sdf" << EOF
<?xml version="1.0" ?>
<sdf version="1.10">
  <model name="$MODEL_NAME">
    <static>true</static>
    <link name="link">

      <!-- Visual: full mesh — materials/textures from the mesh file -->
      <!-- NOTE: requires GZ_MESH_FORCE_ASSIMP=1 for .dae files -->
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
if [ "$EXT" = "obj" ]; then
    MTL_BASE="${MESH_FILENAME%.obj}.mtl"
    if [ -f "$MESH_DEST/$MTL_BASE" ]; then
        echo ">>> Checking texture references in .mtl..."
        MTL_TEXTURES=$(grep "map_" "$MESH_DEST/$MTL_BASE" | awk '{print $2}' | grep -v "^http")
        for TEX in $MTL_TEXTURES; do
            TEX_NAME=$(basename "$TEX")
            if [ ! -f "$MESH_DEST/$TEX_NAME" ]; then
                echo "[WARNING] Texture referenced in .mtl but not found: $TEX_NAME"
                echo "          Copy it into: $MESH_DEST/"
            fi
        done
    fi
fi

# ── Print next steps ─────────────────────────────────────────
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
if [ "$EXT" = "dae" ] || [ "$EXT" = "obj" ]; then
echo "    export GZ_MESH_FORCE_ASSIMP=1   # required for .$EXT — bypasses buggy COLLADA loader"
fi
if [ "$EXT" = "glb" ] || [ "$EXT" = "gltf" ]; then
echo "    # GZ_MESH_FORCE_ASSIMP not needed — assimp handles .$EXT by default"
echo ""
echo "  NOTE: If the model leans sideways, uncomment the <pose> line in model.sdf:"
echo "    <pose>0 0 0 -1.5708 0 0</pose>  ← fixes Y-up → Z-up rotation"
fi
echo "    gz sim -r /path/to/your_world.sdf"
echo ""
echo "  4. If model is wrong size, check bounding box then adjust <scale>:"
echo "    gz model -m ${MODEL_NAME}_1 --pose"
echo "============================================================"
echo ""
