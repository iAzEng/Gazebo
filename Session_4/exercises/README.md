# Session 04 — Exercise

## 🎯 Goal

Import an external 3D mesh from the internet into Gazebo Sim 8, integrate it into a PX4-compatible world, and fly the X500 drone alongside it.

> **Path note:** All paths below use `~` which expands to your home directory (`/home/YOUR_USERNAME`). Replace `~/Videos/Session_4` with wherever you cloned this course material.

---

## 📋 Tasks

### Task 1 — Import a .STL model manually

Find and download any `.stl` model (a building, container, vehicle, or structure). Good sources:
- [Thingiverse](https://www.thingiverse.com)
- [GrabCAD](https://grabcad.com/library) — filter by format: STL
- [NASA 3D Resources](https://nasa3d.arc.nasa.gov/models)

Create the model folder structure **by hand** (as shown in Part 1A of the README):

```bash
mkdir -p ~/PX4-Autopilot/Tools/simulation/gz/models/my_stl_model/meshes
cp /path/to/your/model.stl \
   ~/PX4-Autopilot/Tools/simulation/gz/models/my_stl_model/meshes/model.stl
```

Write `model.config` and `model.sdf` manually — do not use the script for this task. Refer to the templates in Part 1A of the README.

Verify:
- [ ] `model.config` and `model.sdf` exist in the model folder
- [ ] `meshes/` contains your `.stl` file
- [ ] Run `gz sdf -k ~/PX4-Autopilot/Tools/simulation/gz/models/my_stl_model/model.sdf` — no errors

---

### Task 2 — Test the model in Gazebo

Add your model to the example world. Open `worlds/external_world.sdf` and add:

```xml
<include>
  <uri>model://my_stl_model</uri>
  <name>my_stl_model_1</name>
  <pose>15 0 0 0 0 0</pose>
</include>
```

Copy to PX4 and launch (run from inside the `Session_4/` folder):
```bash
cp worlds/external_world.sdf \
   ~/PX4-Autopilot/Tools/simulation/gz/worlds/external_world.sdf

export GZ_SIM_RESOURCE_PATH=~/PX4-Autopilot/Tools/simulation/gz/models
export GZ_SIM_SERVER_CONFIG_PATH=~/.simulation-gazebo/server.config
export GZ_SIM_SYSTEM_PLUGIN_PATH=~/PX4-Autopilot/build/px4_sitl_default/src/modules/simulation/gz_plugins
gz sim -r ~/PX4-Autopilot/Tools/simulation/gz/worlds/external_world.sdf
```

- [ ] Does the model appear in Gazebo at the correct position?
- [ ] Is the scale correct (not huge, not microscopic)?
- [ ] If scale is wrong, what unit was the source model in? What scale factor did you use to fix it?

---

### Task 3 — Run with PX4

```bash
# Terminal 2 (after Gazebo window is visible)
cd ~/PX4-Autopilot
PX4_GZ_STANDALONE=1 PX4_GZ_WORLD=external_world make px4_sitl gz_x500
```

- [ ] Does the drone spawn correctly?
- [ ] Does QGroundControl connect?
- [ ] Can you arm and fly the drone near your imported model?
- [ ] Does the drone collide with the model (if you fly into it)?

---

### Task 4 — Import a .DAE or .OBJ model with textures using the script

Download a model with materials/textures from [Sketchfab](https://sketchfab.com/search?features=downloadable&licenses=322a749bcfa841b29dff1e8a1bb74b0b) — filter by "Downloadable" and free license. Download as **Collada (.dae)** or **OBJ**.

```bash
# Extract the downloaded zip, then run the script
bash scripts/import_asset.sh my_textured_model /path/to/extracted/model.dae
# When prompted, enter the root download folder (the one that contains textures/)
```

- [ ] Does the model load with its original colours and textures in Gazebo?
- [ ] What did the script do differently compared to the manual steps in Task 1?
- [ ] Open the generated `model.sdf` — what scale and pose values were set, and why?

---

### Task 5 — Examine the model folder structure you created

Pick any model you imported in Tasks 1–4. Without looking at the README, reconstruct in your own words why each file is needed.

```bash
# List everything in your model folder
find ~/PX4-Autopilot/Tools/simulation/gz/models/my_model/ -type f | sort

# Read the model.sdf
cat ~/PX4-Autopilot/Tools/simulation/gz/models/my_model/model.sdf

# For a GLB model: check how many textures are embedded
python3 - ~/PX4-Autopilot/Tools/simulation/gz/models/my_model/meshes/model.glb << 'EOF'
import sys, json
data = open(sys.argv[1], 'rb').read()
chunk = data[20:]
length = int.from_bytes(chunk[:4], 'little')
j = json.loads(chunk[8:8+length])
print(f"images   : {len(j.get('images', []))}")
print(f"materials: {len(j.get('materials', []))}")
EOF
```

Answer these questions about your chosen model:
- [ ] What does `model.config` contain, and what would break if it were missing?
- [ ] What is the `model://` URI scheme, and how does Gazebo resolve it to a file path?
- [ ] What is the `<pose>` on the `<link>` for, and when is it needed?
- [ ] What `<scale>` is applied, and what unit was the original model in?
- [ ] Add this model to `external_world.sdf` alongside the STL model from Task 1 — do both appear at the same time?

---

## 🔍 Self-Check Questions

1. What is the difference between `.stl` and `.glb` formats? When would you choose each?
2. Why does Gazebo fail to find a texture even though the texture file exists in the model folder?
3. A model downloads as `.fbx`. What do you do before importing it into Gazebo?
4. A model that is 5 metres tall in real life appears as 5 millimetres in Gazebo. What is the most likely source unit and what scale factor do you apply?
5. Why is it better to use a simple bounding box for collision instead of the full mesh?
6. What is the difference between using `model://ModelName/meshes/file.glb` vs `meshes/file.glb` as a URI — and where is each form used?
7. What are the three files that make up a GLTF multi-file model, and why must they all be in the same folder?
