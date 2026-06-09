## 🎯 Learning Objectives

By the end of this session you will be able to:

- [ ] Understand the mesh formats Gazebo Sim 8 supports and when to use each
- [ ] Create `model.config` and `model.sdf` from scratch to wrap an external mesh
- [ ] Build the Gazebo model folder structure manually for `.stl` and `.glb` files
- [ ] Build the model folder structure manually for a `.gltf` multi-file model
- [ ] Use the import script to automate `.dae` and `.obj` imports with texture embedding
- [ ] Diagnose and fix texture path errors
- [ ] Correct model scale (Gazebo uses meters)
- [ ] Run a PX4 world containing your imported 3D asset

---

## 📚 Concepts Covered

### 1. Supported Mesh Formats in Gazebo Sim 8

| Format | Extension | Colors / Materials | Textures | Notes |
|--------|-----------|-------------------|----------|-------|
| glTF / GLB | `.glb` | ✅ (PBR) | ✅ embedded | **Best — recommended for Sketchfab** |
| Wavefront OBJ | `.obj` | ✅ (via `.mtl`) | ✅ | Widely available, reliable |
| COLLADA | `.dae` | ✅ | ✅ | Requires `GZ_MESH_FORCE_ASSIMP=1` |
| STL | `.stl` | ❌ | ❌ | Geometry only — simplest to import |
| FBX | `.fbx` | — | — | **Not supported** — convert to `.glb` via Blender |

**Rule of thumb:** Always use `.glb` in Gazebo Harmonic — it is the only format that reliably loads with textures. Workflow:
- Sketchfab: download as **"Autoconverted format (GLTF)"** → gives `.glb`
- If you only have `.obj` or `.dae`: run `import_asset.sh` which **auto-converts to .glb** via `convert_to_glb.py`
- Convert `.fbx` with Blender → File → Export → glTF 2.0 (choose .glb)

> ⚠️ **Why .dae and .obj fail in Gazebo Harmonic:**
> - **`.dae`** → Gazebo's COLLADA loader crashes (`LoadPolylist → parseInt → segfault`)
> - **`.obj`** → Both the native loader and assimp silently drop textures; model appears white
> - **`.glb`** → Loaded by assimp by default; textures embedded; works reliably
>
> The `import_asset.sh` script now converts `.obj`/`.dae` → `.glb` automatically using `trimesh`. GLB is the stable target format for all imports.

---

### 2. Model Folder Structure with a Mesh

A Gazebo model that uses a mesh file follows the same folder structure as a Fuel model, but you create the SDF yourself:

```
PX4-Autopilot/Tools/simulation/gz/models/
└── ModelName/                ← folder name = model:// name
    ├── model.config          ← required Gazebo metadata
    ├── model.sdf             ← model definition (references the mesh)
    └── meshes/               ← mesh files and textures
        ├── model.dae         ← or .obj, .stl
        ├── model.mtl         ← (OBJ only) material definitions
        └── texture.png       ← textures must be in the same folder as the mesh
```

> ⚠️ **Texture path rule:** When Gazebo loads a `.dae` or `.obj`, it resolves texture paths **relative to the mesh file**. If your `.mtl` references `texture.png`, that file must be in the same folder as the `.mtl`. Keep textures in `meshes/` alongside the mesh files — not in a separate `materials/textures/` subfolder.

---

### 3. The `<mesh>` Geometry Tag

In `model.sdf`, use `<mesh>` inside `<geometry>` to reference a mesh file:

```xml
<visual name="visual">
  <geometry>
    <mesh>
      <uri>model://ModelName/meshes/model.dae</uri>
      <scale>1 1 1</scale>
    </mesh>
  </geometry>
</visual>
```

The `<uri>` uses the `model://` scheme — Gazebo resolves this using `GZ_SIM_RESOURCE_PATH`.

For the **collision** shape, using the full mesh is expensive. For static environmental props a simple bounding box is usually enough:

```xml
<collision name="collision">
  <geometry>
    <box><size>WIDTH DEPTH HEIGHT</size></box>  <!-- bounding box approximation -->
  </geometry>
</collision>
```

---

### 4. Scale and Units

Gazebo Sim 8 uses **meters**. Models downloaded from the internet are often in different units:

| Source unit | Scale value | Example |
|------------|-------------|---------|
| meters (correct) | `1 1 1` | Most Gazebo Fuel models |
| centimeters | `0.01 0.01 0.01` | Many CAD models |
| millimeters | `0.001 0.001 0.001` | Engineering / 3D print files |
| inches | `0.0254 0.0254 0.0254` | Many US CAD/engineering models |

**How to find the right scale:**
1. Import with `scale 1 1 1` first
2. Run the world and look at the model — is it enormous or microscopic?
3. Use `gz model -m model_name --pose` to see its bounding size
4. Adjust scale accordingly

---

### 5. Format Conversion with Blender

If your model is in `.fbx`, `.3ds`, or another unsupported format:

```
Blender → File → Import → [your format]
         → File → Export → Collada (.dae)
```

**Tips:**
- Enable "Selection Only" if your file has multiple objects
- Check "Include UV Textures" when exporting `.dae`
- The exported `.dae` should be placed in `meshes/` alongside its textures

Blender is free and available at [blender.org](https://www.blender.org/).

---

### 6. Visual vs Collision Mesh

| | Visual | Collision |
|---|---|---|
| Purpose | What the model looks like in the GUI | What the physics engine uses for contact detection |
| Recommended | Full mesh (`.dae` / `.obj`) | Simple bounding box or primitive |
| Performance | No impact | High-poly mesh collision is expensive |
| For flying drone sims | Use full mesh | Bounding box is usually sufficient |

---

## 📂 Files in This Session

```
Session_4/
├── README.md
├── worlds/
│   └── external_world.sdf     ← PX4-compatible world with an imported mesh model
├── scripts/
│   └── convert_to_glb.py      ← helper: convert .dae and .obj to .glb
│   └── import_asset.sh        ← helper: creates model folder + generates SDF templates
└── exercises/
    └── README.md
```

---

## 🛠️ Guided Walkthrough

---

### Part 1 — Import .STL and .GLB Files

Build the model folder from scratch. These two formats represent opposite ends of the complexity spectrum: STL is geometry only (simplest), GLB is fully textured (recommended for real models).

---

#### 1A — STL (Geometry Only)

STL has no colour, no materials, no textures — pure geometry. It is the simplest possible import.

##### Step 1 — Download a .stl model

Good sources for free `.stl` files:
- [Thingiverse](https://www.thingiverse.com) — many downloadable `.stl` files
- [GrabCAD](https://grabcad.com/library) — engineering models (filter by format)
- [NASA 3D Resources](https://nasa3d.arc.nasa.gov/models) — spacecraft, satellites, structures

Choose something with a clear real-world size (e.g. a shipping container, building, or vehicle).

##### Step 2 — Create the model folder manually

```
PX4-Autopilot/Tools/simulation/gz/models/
└── my_container/
    ├── model.config
    ├── model.sdf
    └── meshes/
        └── model.stl
```

```bash
mkdir -p ~/PX4-Autopilot/Tools/simulation/gz/models/my_container/meshes
cp /path/to/downloaded/container.stl \
   ~/PX4-Autopilot/Tools/simulation/gz/models/my_container/meshes/model.stl
```

##### Step 3 — Create model.config

```bash
cat > ~/PX4-Autopilot/Tools/simulation/gz/models/my_container/model.config << 'EOF'
<?xml version="1.0"?>
<model>
  <name>my_container</name>
  <version>1.0</version>
  <sdf version="1.10">model.sdf</sdf>
  <description>Imported STL model</description>
</model>
EOF
```

##### Step 4 — Create model.sdf

Create `~/PX4-Autopilot/Tools/simulation/gz/models/my_container/model.sdf`:

```xml
<?xml version="1.0" ?>
<sdf version="1.10">
  <model name="my_container">
    <static>true</static>
    <link name="link">

      <visual name="visual">
        <geometry>
          <mesh>
            <uri>model://my_container/meshes/model.stl</uri>
            <scale>1 1 1</scale>
          </mesh>
        </geometry>
        <material>
          <!-- STL has no built-in colour — set one manually -->
          <ambient>0.6 0.6 0.6 1</ambient>
          <diffuse>0.6 0.6 0.6 1</diffuse>
          <specular>0.2 0.2 0.2 1</specular>
        </material>
      </visual>

      <collision name="collision">
        <geometry>
          <box><size>6 2.5 2.6</size></box>
        </geometry>
      </collision>

    </link>
  </model>
</sdf>
```

##### Step 5 — Add to world and test

Add to `worlds/external_world.sdf`:
```xml
<include>
  <uri>model://my_container</uri>
  <name>container_1</name>
  <pose>15 0 0 0 0 0</pose>
</include>
```

Launch:
```bash
export GZ_SIM_RESOURCE_PATH=~/PX4-Autopilot/Tools/simulation/gz/models
export GZ_SIM_SERVER_CONFIG_PATH=~/.simulation-gazebo/server.config
export GZ_SIM_SYSTEM_PLUGIN_PATH=~/PX4-Autopilot/build/px4_sitl_default/src/modules/simulation/gz_plugins
gz sim -r ~/PX4-Autopilot/Tools/simulation/gz/worlds/external_world.sdf
```

If the model is:
- **Too big / too small** → adjust `<scale>` in model.sdf
- **Underground** → raise the Z value in the `<include>` pose in the world file
- **Grey** → expected for STL — colour comes from the `<material>` block you wrote

---

#### 1B — GLB (Textures Embedded)

GLB (binary glTF) is the cleanest format for Gazebo Harmonic — textures are packed inside the single `.glb` file so there are no extra files to copy or configure.

> **Note on Y-up vs Z-up:** glTF/GLB uses Y-up coordinates; Gazebo uses Z-up. Without correction the model will appear lying on its side. Fix: add `<pose>0 0 0 1.5708 0 0</pose>` to the `<link>` — this rotates 90° around the X axis.

##### Step 1 — Download a .glb model from Sketchfab

1. Go to [sketchfab.com](https://sketchfab.com) → filter **Downloadable** + free licence
2. Click **Download 3D Model** → choose **"Autoconverted format (glTF)"** — this gives a `.glb` file

##### Step 2 — Create the model folder manually

```
PX4-Autopilot/Tools/simulation/gz/models/
└── my_car/
    ├── model.config
    ├── model.sdf
    └── meshes/
        └── model.glb       ← textures embedded inside the GLB
```

```bash
mkdir -p ~/PX4-Autopilot/Tools/simulation/gz/models/my_car/meshes
cp /path/to/downloaded/model.glb \
   ~/PX4-Autopilot/Tools/simulation/gz/models/my_car/meshes/model.glb
```

##### Step 3 — Create model.config

```bash
cat > ~/PX4-Autopilot/Tools/simulation/gz/models/my_car/model.config << 'EOF'
<?xml version="1.0"?>
<model>
  <name>my_car</name>
  <version>1.0</version>
  <sdf version="1.10">model.sdf</sdf>
  <description>Imported GLB model</description>
</model>
EOF
```

##### Step 4 — Create model.sdf

```xml
<?xml version="1.0" ?>
<sdf version="1.10">
  <model name="my_car">
    <static>true</static>
    <link name="link">

      <!-- glTF/GLB uses Y-up; Gazebo uses Z-up — rotate 90° around X -->
      <pose>0 0 0 1.5708 0 0</pose>

      <visual name="visual">
        <geometry>
          <mesh>
            <uri>model://my_car/meshes/model.glb</uri>
            <scale>1 1 1</scale>
          </mesh>
        </geometry>
      </visual>

      <collision name="collision">
        <geometry>
          <box><size>1 1 1</size></box>
        </geometry>
      </collision>

    </link>
  </model>
</sdf>
```

> No `<material>` block needed — the GLB carries its own PBR materials.

##### Step 5 — Add to world and test

```xml
<include>
  <uri>model://my_car</uri>
  <name>car_1</name>
  <pose>15 0 0 0 0 0</pose>
</include>
```

```bash
export GZ_SIM_RESOURCE_PATH=~/PX4-Autopilot/Tools/simulation/gz/models
export GZ_SIM_SERVER_CONFIG_PATH=~/.simulation-gazebo/server.config
export GZ_SIM_SYSTEM_PLUGIN_PATH=~/PX4-Autopilot/build/px4_sitl_default/src/modules/simulation/gz_plugins
# GZ_MESH_FORCE_ASSIMP not needed — assimp handles .glb by default
gz sim -r ~/PX4-Autopilot/Tools/simulation/gz/worlds/external_world.sdf
```

---

### Part 2 — Import a .GLTF File (Multi-file Format)

GLTF (text glTF) is different from GLB: instead of one binary file, it splits the data across three components that must travel together:

```
scene.gltf     — scene description (JSON text)
scene.bin      — binary geometry buffer (vertices, normals, UVs)
textures/      — folder of texture images
```

All three must be in the **same folder** in `meshes/` — if any piece is missing the model loads with broken geometry or no textures.

##### Step 1 — Download a GLTF model from Sketchfab

1. Go to [sketchfab.com](https://sketchfab.com) → choose a downloadable model
2. Click **Download 3D Model** → choose **"glTF"** (the multi-file option, not GLB)
3. Extract the zip — you get something like:

```
car_scene/
├── scene.gltf
├── scene.bin
├── license.txt
└── textures/
    ├── body_baseColor.png
    ├── body_metallicRoughness.png
    ├── glass_baseColor.png
    └── ...
```

##### Step 2 — Create the model folder manually

```
PX4-Autopilot/Tools/simulation/gz/models/
└── car_scene/
    ├── model.config
    ├── model.sdf
    └── meshes/
        ├── scene.gltf       ← scene description
        ├── scene.bin        ← geometry buffer (same name as .gltf)
        └── textures/        ← texture images referenced from scene.gltf
            ├── body_baseColor.png
            ├── body_metallicRoughness.png
            └── ...
```

```bash
mkdir -p ~/PX4-Autopilot/Tools/simulation/gz/models/car_scene/meshes

cp /path/to/car_scene/scene.gltf \
   ~/PX4-Autopilot/Tools/simulation/gz/models/car_scene/meshes/

cp /path/to/car_scene/scene.bin \
   ~/PX4-Autopilot/Tools/simulation/gz/models/car_scene/meshes/

cp -r /path/to/car_scene/textures \
      ~/PX4-Autopilot/Tools/simulation/gz/models/car_scene/meshes/textures
```

> **Why do all three need to be together?** The `scene.gltf` references the binary buffer as `"scene.bin"` and the textures as `"textures/body_baseColor.png"` — both are **relative paths**. If you move the `.gltf` without the other files, Gazebo cannot find them.

##### Step 3 — Create model.config

```bash
cat > ~/PX4-Autopilot/Tools/simulation/gz/models/car_scene/model.config << 'EOF'
<?xml version="1.0"?>
<model>
  <name>car_scene</name>
  <version>1.0</version>
  <sdf version="1.10">model.sdf</sdf>
  <description>Imported GLTF model</description>
</model>
EOF
```

##### Step 4 — Create model.sdf

GLTF also uses Y-up coordinates — the same `<pose>` fix applies:

```xml
<?xml version="1.0" ?>
<sdf version="1.10">
  <model name="car_scene">
    <static>true</static>
    <link name="link">

      <!-- GLTF uses Y-up; Gazebo uses Z-up — rotate 90° around X -->
      <pose>0 0 0 1.5708 0 0</pose>

      <visual name="visual">
        <geometry>
          <mesh>
            <uri>model://car_scene/meshes/scene.gltf</uri>
            <scale>1 1 1</scale>
          </mesh>
        </geometry>
      </visual>

      <collision name="collision">
        <geometry>
          <box><size>1 1 1</size></box>
        </geometry>
      </collision>

    </link>
  </model>
</sdf>
```

##### Step 5 — Add to world and test

```xml
<include>
  <uri>model://car_scene</uri>
  <name>car_scene_1</name>
  <pose>20 0 0 0 0 0</pose>
</include>
```

```bash
export GZ_SIM_RESOURCE_PATH=~/PX4-Autopilot/Tools/simulation/gz/models
export GZ_SIM_SERVER_CONFIG_PATH=~/.simulation-gazebo/server.config
export GZ_SIM_SYSTEM_PLUGIN_PATH=~/PX4-Autopilot/build/px4_sitl_default/src/modules/simulation/gz_plugins
# GZ_MESH_FORCE_ASSIMP not needed — assimp handles .gltf by default
gz sim -r ~/PX4-Autopilot/Tools/simulation/gz/worlds/external_world.sdf
```

If the model loads but has no texture: verify that `meshes/textures/` exists and contains the image files. The `.gltf` file references them by relative path.

---

### Part 3 — Import .DAE and .OBJ Files Using the Script

> **Why a script for these formats?** `.dae` and `.obj` from Sketchfab have two problems that require extra work to fix manually: (1) Gazebo's COLLADA loader crashes on most real-world `.dae` files, and (2) Sketchfab separates the textures into a `textures/` folder that the mesh file does not reference. The `import_asset.sh` script handles both automatically by converting to `.glb` first.

The script does the following for `.dae` and `.obj` input:

1. Asks for the root download folder (the parent that contains `textures/`)
2. Runs `convert_to_glb.py` which:
   - Finds the `textures/` folder
   - For `.dae`: patches the COLLADA XML in a temp copy to wire up the albedo texture, then converts to GLB via trimesh
   - For `.obj`: rebuilds the missing `.mtl` by matching material names to texture filenames, then converts
   - Auto-centres the geometry so the model sits at the world origin
3. Creates the model folder in PX4 with the GLB
4. Generates `model.config` and `model.sdf` with `scale 0.1 0.1 0.1` and the Y-up pose fix

Sketchfab downloads typically look like this:
```
downloaded-model/
├── source/
│   └── model.dae   (or model.obj)
└── textures/
    ├── BASE_albedo.jpeg
    └── ...
```

#### Import a .DAE model

```bash
bash scripts/import_asset.sh cartoon_car \
    ~/Downloads/cartoon-car/source/model/model.dae
```

When prompted, enter the root download folder (the one that contains `textures/`):
```
Enter the root download folder (parent of textures/): ~/Downloads/cartoon-car
```

#### Import a .OBJ model

```bash
bash scripts/import_asset.sh sea_house \
    ~/Downloads/sea-house/source/sea.obj
```

```
Enter the root download folder (parent of textures/): ~/Downloads/sea-house
```

#### What the script generates

After a successful run, the model folder is ready:
```
PX4-Autopilot/Tools/simulation/gz/models/cartoon_car/
├── model.config
├── model.sdf          ← scale 0.1 + Y-up pose already set
└── meshes/
    └── model.glb      ← converted GLB with textures embedded
```

#### Add to world and test

```xml
<include>
  <uri>model://cartoon_car</uri>
  <name>car_1</name>
  <pose>15 0 0 0 0 0</pose>
</include>
```

```bash
export GZ_SIM_RESOURCE_PATH=~/PX4-Autopilot/Tools/simulation/gz/models
export GZ_SIM_SERVER_CONFIG_PATH=~/.simulation-gazebo/server.config
export GZ_SIM_SYSTEM_PLUGIN_PATH=~/PX4-Autopilot/build/px4_sitl_default/src/modules/simulation/gz_plugins
# No GZ_MESH_FORCE_ASSIMP needed — the script converted everything to GLB
gz sim -r ~/PX4-Autopilot/Tools/simulation/gz/worlds/external_world.sdf
```

> **The script also works for STL, GLB, and GLTF.** Once you understand the folder structure from Parts 1 and 2, you can use `import_asset.sh` for any format — it handles all five supported extensions and skips the conversion step for formats that do not need it:
> ```bash
> bash scripts/import_asset.sh my_container ~/Downloads/container.stl 1
> bash scripts/import_asset.sh my_car       ~/Downloads/model.glb 1
> bash scripts/import_asset.sh car_scene    ~/Downloads/car_scene/scene.gltf 1
> ```

---

## ❓ Common Issues & Debugging

**Gazebo crashes (segmentation fault) when loading a `.dae` file:**

Stack trace to look for: `ColladaLoader::LoadPolylist` → `parseInt` → segfault

This is a known bug in gz-common5's COLLADA loader. **Two fixes — apply both:**

**Fix 1 (primary) — Use assimp instead of the buggy COLLADA loader:**
```bash
export GZ_MESH_FORCE_ASSIMP=1
gz sim -r your_world.sdf
```
This forces Gazebo to use assimp (a well-maintained, robust mesh library) for all formats including `.dae`. The `import_asset.sh` script prints this reminder in its NEXT STEPS output.

**Fix 2 (secondary) — Strip TANGENT/BINORMAL inputs from the `.dae` file:**
```bash
python3 - meshes/model.dae << 'EOF'
import sys, xml.etree.ElementTree as ET
ET.register_namespace('', 'http://www.collada.org/2005/11/COLLADASchema')
path = sys.argv[1]
tree = ET.parse(path)
root = tree.getroot()
ns = 'http://www.collada.org/2005/11/COLLADASchema'
for pl in root.iter(f'{{{ns}}}polylist'):
    for inp in list(pl.findall(f'{{{ns}}}input')):
        if inp.get('semantic') in ('TANGENT', 'BINORMAL'):
            pl.remove(inp)
tree.write(path, encoding='unicode', xml_declaration=True)
print("Done.")
EOF
```
The `import_asset.sh` script does this automatically for all `.dae` imports.

**Best solution long-term:** Download as `.glb` instead of `.dae` — GLB uses assimp by default, no crash, textures embedded.

**Terminal shows `Unable to extract channel data when splitting metallic roughness map` (repeated):**
- **Non-fatal** — the model loads and renders correctly, ignore these messages
- Cause: The GLB uses a combined ORM (Occlusion/Roughness/Metallic) texture packed into one image. Gazebo's assimp loader in gz-common5 fails to split the G and B channels from it (channels 1 and 2 in the error)
- Visual impact: Minor — base color and geometry are correct; roughness/metallic values fall back to defaults, so material reflectivity may look slightly different from the original
- Models with only `_baseColor` textures (like city/sea GLTF downloads) will NOT show this warning — it only appears on models with full PBR material sets

**Model loads but is invisible (no visual, no error):**
- The mesh URI is wrong — check spelling and case sensitivity
- Run `gz sdf -k model.sdf` to validate
- Check `GZ_SIM_RESOURCE_PATH` is set: `echo $GZ_SIM_RESOURCE_PATH`

**OBJ model loads but is completely white (textures not applied) even with GZ_MESH_FORCE_ASSIMP=1:**

Gazebo's OBJ loader (both native and assimp) is unreliable with texture resolution. The correct fix is to **convert the OBJ to GLB first** using the provided script — this embeds all textures into one file that loads reliably:
```bash
python3 scripts/convert_to_glb.py /path/to/model.obj /path/to/model.glb
bash scripts/import_asset.sh my_model /path/to/model.glb 1
```
The `import_asset.sh` script now does this automatically — it converts .obj and .dae to .glb before creating the model folder.

**OBJ converts to GLB but textures are still missing (all white after conversion):**
- The `.mtl` file is missing — the OBJ references `mtllib file.mtl` but that file was not included in the download
- Check: `grep "^mtllib" your_model.obj` — if it names a `.mtl` file, verify that file exists alongside the OBJ
- If the `.mtl` is missing, check the texture filenames — they often encode the material name:
  - OBJ has `usemtl sea_house_Material__25` → look for a texture with `Material__25` in the name
  - Create a minimal `.mtl` file manually:
    ```
    newmtl sea_house_Material__25
    Ka 1 1 1
    Kd 1 1 1
    d 1
    illum 1
    map_Kd path/to/texture.png
    ```
- Then re-run the conversion

**Model is the right shape but completely grey (no texture):**
- Texture file is not found — it must be in the same folder as the `.mtl`/`.dae`
- Check what path the `.mtl` references: `grep map_ meshes/your_model.mtl`
- If it references `textures/texture.png`, create a `meshes/textures/` subfolder and put the texture there

**`[Err] Could not resolve file [texture.png]`:**
- Gazebo cannot find the texture file
- The `.mtl` references `texture.png` but that file is not in `meshes/`
- Fix: copy (or symlink) the texture into the same folder as the `.mtl`:
  ```bash
  cp materials/textures/texture.png meshes/texture.png
  # or symlink:
  ln -s ../materials/textures/texture.png meshes/texture.png
  ```

**Model is enormous (fills the whole world) or microscopic:**
- Wrong scale — check source units and adjust `<scale>` in model.sdf:
  ```
  Source in cm  → scale 0.01 0.01 0.01
  Source in mm  → scale 0.001 0.001 0.001
  Source in inches → scale 0.0254 0.0254 0.0254
  ```

**Model is underground:**
- The mesh origin (0,0,0) is at the center or top of the model
- Raise the pose Z value in the `<include>` block until it sits on the ground
- Check bounding box: `gz model -m model_name --pose`

**FBX file does not load:**
- Gazebo does not support `.fbx` — convert to `.dae` using Blender first:
  `Blender → File → Import → FBX → File → Export → Collada (.dae)`

**Model has correct textures but colors look wrong:**
- The `.dae` may have baked lighting — export from Blender with "Include UV Textures" and no baked light
- Or the material values (ambient/diffuse/specular) in the `.mtl` may be extreme — edit the `.mtl` to normalize them

**SDF parse error on `<collision>` tag:**
- Missing closing `</geometry>` tag — SDF is XML, every tag must be properly closed
- Run `gz sdf -k model.sdf` to see the exact line

---

## 🔗 References

- [Gazebo: Import a Mesh](https://gazebosim.org/docs/harmonic/import_mesh/)
- [Gazebo: Model SDF specification](http://sdformat.org/spec?ver=1.10&elem=model)
- [Blender download](https://www.blender.org/download/)
- [Sketchfab — free downloadable models](https://sketchfab.com/search?features=downloadable&licenses=322a749bcfa841b29dff1e8a1bb74b0b)
- [GrabCAD Library](https://grabcad.com/library)
- [Thingiverse](https://www.thingiverse.com)
- [NASA 3D Resources](https://nasa3d.arc.nasa.gov/models)
