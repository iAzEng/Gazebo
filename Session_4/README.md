## 🎯 Learning Objectives

By the end of this session you will be able to:

- [ ] Understand the mesh formats Gazebo Sim 8 supports and when to use each
- [ ] Create `model.config` and `model.sdf` from scratch to wrap an external mesh
- [ ] Import a `.stl` file into Gazebo as a static model
- [ ] Import a `.obj` or `.dae` file with materials and textures
- [ ] Diagnose and fix texture path errors
- [ ] Correct model scale (Gazebo uses meters)
- [ ] Run a PX4 world containing your imported 3D asset

---

## 📚 Concepts Covered

### 1. Supported Mesh Formats in Gazebo Sim 8

| Format | Extension | Colors / Materials | Textures | Notes |
|--------|-----------|-------------------|----------|-------|
| COLLADA | `.dae` | ✅ | ✅ | Best support — preferred format |
| Wavefront OBJ | `.obj` | ✅ (via `.mtl`) | ✅ | Widely available, reliable |
| STL | `.stl` | ❌ | ❌ | Geometry only — simplest to import |
| FBX | `.fbx` | — | — | **Not supported** — convert to `.dae` first |
| glTF / GLB | `.gltf` `.glb` | ✅ | ✅ | Newer, support is improving |

**Rule of thumb:** Download as `.dae` when possible. Fall back to `.obj` if `.dae` is not available. Convert `.fbx` using Blender before importing.

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
gaz/
├── README.md
├── worlds/
│   └── external_world.sdf     ← PX4-compatible world with an imported mesh model
├── scripts/
│   └── import_asset.sh        ← helper: creates model folder + generates SDF templates
└── exercises/
    └── README.md
```

---

## 🛠️ Guided Walkthrough

### Part 1 — Import a .STL File (No Textures)

This is the simplest import case. STL has geometry only — no colors, no textures.

#### Step 1 — Download a .stl model

Good sources for free `.stl` files:
- [Thingiverse](https://www.thingiverse.com) — many downloadable `.stl` files
- [GrabCAD](https://grabcad.com/library) — engineering models (filter by format)
- [NASA 3D Resources](https://nasa3d.arc.nasa.gov/models) — spacecraft, satellites, structures

Choose something with a clear real-world size (e.g. a shipping container, building, or vehicle).

#### Step 2 — Set up the model folder

Use the helper script to create the folder structure automatically:

```bash
bash scripts/import_asset.sh my_container /path/to/downloaded/container.stl 1
```

Or create it manually:
```bash
mkdir -p /home/az/PX4-Autopilot/Tools/simulation/gz/models/my_container/meshes
cp /path/to/container.stl \
   /home/az/PX4-Autopilot/Tools/simulation/gz/models/my_container/meshes/model.stl
```

#### Step 3 — Create model.config

```bash
cat > /home/az/PX4-Autopilot/Tools/simulation/gz/models/my_container/model.config << 'EOF'
<?xml version="1.0"?>
<model>
  <name>my_container</name>
  <version>1.0</version>
  <sdf version="1.10">model.sdf</sdf>
  <description>Imported STL model</description>
</model>
EOF
```

#### Step 4 — Create model.sdf

Create `/home/az/PX4-Autopilot/Tools/simulation/gz/models/my_container/model.sdf`:

```xml
<?xml version="1.0" ?>
<sdf version="1.10">
  <model name="my_container">
    <static>true</static>
    <link name="link">

      <!-- STL has no color — apply a material here to give it color -->
      <visual name="visual">
        <geometry>
          <mesh>
            <uri>model://my_container/meshes/model.stl</uri>
            <scale>1 1 1</scale>   <!-- adjust if model is wrong size -->
          </mesh>
        </geometry>
        <material>
          <!-- STL has no built-in color; set one manually -->
          <ambient>0.6 0.6 0.6 1</ambient>
          <diffuse>0.6 0.6 0.6 1</diffuse>
          <specular>0.2 0.2 0.2 1</specular>
        </material>
      </visual>

      <!-- Simplified bounding box for collision -->
      <collision name="collision">
        <geometry>
          <box><size>6 2.5 2.6</size></box>  <!-- adjust to match model size -->
        </collision>
      </collision>

    </link>
  </model>
</sdf>
```

#### Step 5 — Test in Gazebo

```bash
export GZ_SIM_RESOURCE_PATH=/home/az/PX4-Autopilot/Tools/simulation/gz/models
gz sim -r worlds/external_world.sdf
```

Look for the model in the viewport. If it is:
- **Too big or too small** → adjust `<scale>` in model.sdf
- **Underground** → adjust the pose in the world `<include>` block
- **Grey / no color** → normal for STL — set `<material>` in `<visual>`

#### Step 6 — Run with PX4

```bash
# Copy world to PX4 directory (once)
cp /home/az/Videos/Session_4/worlds/external_world.sdf \
   /home/az/PX4-Autopilot/Tools/simulation/gz/worlds/external_world.sdf

# Terminal 1
export GZ_SIM_RESOURCE_PATH=/home/az/PX4-Autopilot/Tools/simulation/gz/models
export GZ_SIM_SERVER_CONFIG_PATH=/home/az/.simulation-gazebo/server.config
export GZ_SIM_SYSTEM_PLUGIN_PATH=/home/az/PX4-Autopilot/build/px4_sitl_default/src/modules/simulation/gz_plugins
gz sim -r /home/az/PX4-Autopilot/Tools/simulation/gz/worlds/external_world.sdf

# Terminal 2
cd ~/PX4-Autopilot
PX4_GZ_STANDALONE=1 PX4_GZ_WORLD=external_world make px4_sitl gz_x500
```

---

### Part 2 — Import a .OBJ File with Textures (Ambulance Case Study)

This walkthrough uses the **Ambulance** model already downloaded in Session 3. It demonstrates the complete `.obj` + texture import workflow, including the most common issue: texture path resolution.

The model is at:
```
/home/az/PX4-Autopilot/Tools/simulation/gz/models/Ambulance/
├── model.config
├── model.sdf
└── meshes/
    ├── ambulance.obj
    ├── ambulance.mtl     ← references ambulance.png
    └── ambulance.png     ← texture must be alongside the .mtl
```

#### Step 1 — Understand the model structure

```bash
# Look at the model files
ls /home/az/PX4-Autopilot/Tools/simulation/gz/models/Ambulance/meshes/

# Check what texture the .mtl references
grep "map_" /home/az/PX4-Autopilot/Tools/simulation/gz/models/Ambulance/meshes/ambulance.mtl
```

You will see `map_Ka ambulance.png` — the .mtl looks for `ambulance.png` in the same folder as itself (i.e. `meshes/`). And `ambulance.png` is already there. ✅

#### Step 2 — Read the existing model.sdf

```bash
cat /home/az/PX4-Autopilot/Tools/simulation/gz/models/Ambulance/model.sdf
```

Key points from the SDF:
- `<uri>meshes/ambulance.obj</uri>` — relative path (no `model://` prefix) — valid inside `model.sdf`
- `<scale>0.0254 0.0254 0.0254</scale>` — converts inches → meters (1 inch = 0.0254 m)
- Both `<visual>` and `<collision>` use the full mesh URI

**Note on relative vs absolute URIs in model.sdf:**

Inside `model.sdf` you can use either:
```xml
<uri>meshes/ambulance.obj</uri>           <!-- relative to model root -->
<uri>model://Ambulance/meshes/ambulance.obj</uri>  <!-- absolute via resource path -->
```
Both work. Use `model://` in world files (`<include>` blocks); use relative paths inside `model.sdf` itself.

#### Step 3 — Understand the scale

```
0.0254 × 0.0254 × 0.0254
```

The model was built in inches. `1 inch = 0.0254 meters`. If you import a model and it looks huge, check the source units and calculate the correct scale factor.

#### Step 4 — Run the Ambulance in the example world

First, update `worlds/external_world.sdf` to include the Ambulance:

```xml
<include>
  <uri>model://Ambulance</uri>
  <name>ambulance_1</name>
  <pose>15 0 0 0 0 0</pose>
</include>
```

Then launch:
```bash
export GZ_SIM_RESOURCE_PATH=/home/az/PX4-Autopilot/Tools/simulation/gz/models
export GZ_SIM_SERVER_CONFIG_PATH=/home/az/.simulation-gazebo/server.config
export GZ_SIM_SYSTEM_PLUGIN_PATH=/home/az/PX4-Autopilot/build/px4_sitl_default/src/modules/simulation/gz_plugins
gz sim -r /home/az/PX4-Autopilot/Tools/simulation/gz/worlds/external_world.sdf
```

The ambulance should appear at (15, 0, 0) with its texture.

#### Step 5 — Download and import your own .OBJ or .DAE from Sketchfab

1. Go to [https://sketchfab.com](https://sketchfab.com) → filter by "Downloadable" + free license
2. Click **Download** → choose **Collada (.dae)** or **OBJ**
3. Extract the zip file — you will get a folder with:
   - `scene.dae` or `scene.obj` + `scene.mtl`
   - `textures/` folder with `.png`/`.jpg` files

4. **Move textures alongside the mesh file:**
   ```bash
   # Example: textures are in a separate subfolder
   mv /path/to/download/textures/*.png /path/to/download/
   ```

5. Run the import script:
   ```bash
   bash scripts/import_asset.sh my_sketchfab_model /path/to/download/scene.dae 1
   ```

---

## ❓ Common Issues & Debugging

**Model loads but is invisible (no visual, no error):**
- The mesh URI is wrong — check spelling and case sensitivity
- Run `gz sdf -k model.sdf` to validate
- Check `GZ_SIM_RESOURCE_PATH` is set: `echo $GZ_SIM_RESOURCE_PATH`

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
