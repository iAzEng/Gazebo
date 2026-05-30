# Session 04 — Exercise

## 🎯 Goal

Import an external 3D mesh from the internet into Gazebo Sim 8, integrate it into a PX4-compatible world, and fly the X500 drone alongside it.

---

## 📋 Tasks

### Task 1 — Import a .STL model

Find and download any `.stl` model (a building, container, vehicle, or structure). Good sources:
- [Thingiverse](https://www.thingiverse.com)
- [GrabCAD](https://grabcad.com/library) — filter by format: STL
- [NASA 3D Resources](https://nasa3d.arc.nasa.gov/models)

```bash
# Use the import script to set up the folder structure
bash scripts/import_asset.sh my_stl_model /path/to/your/model.stl

# Open the generated model.sdf and update the collision box size
# to approximately match your model's bounding dimensions
```

Verify:
- [ ] `model.config` and `model.sdf` exist in the model folder
- [ ] `meshes/` contains your `.stl` file
- [ ] Run `gz sdf -k model.sdf` — no errors

---

### Task 2 — Test the model in Gazebo

Add your model to the example world. Open `worlds/external_world.sdf` and uncomment/add:

```xml
<include>
  <uri>model://my_stl_model</uri>
  <name>my_model_1</name>
  <pose>15 0 0 0 0 0</pose>
</include>
```

Copy to PX4 and launch:
```bash
cp /home/az/Videos/Session_4/worlds/external_world.sdf \
   /home/az/PX4-Autopilot/Tools/simulation/gz/worlds/external_world.sdf

export GZ_SIM_RESOURCE_PATH=/home/az/PX4-Autopilot/Tools/simulation/gz/models
export GZ_SIM_SERVER_CONFIG_PATH=/home/az/.simulation-gazebo/server.config
export GZ_SIM_SYSTEM_PLUGIN_PATH=/home/az/PX4-Autopilot/build/px4_sitl_default/src/modules/simulation/gz_plugins
gz sim -r /home/az/PX4-Autopilot/Tools/simulation/gz/worlds/external_world.sdf
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

### Task 4 — Import a .DAE or .OBJ model with textures

Download a model with materials/textures from [Sketchfab](https://sketchfab.com/search?features=downloadable&licenses=322a749bcfa841b29dff1e8a1bb74b0b) — filter by "Downloadable" and free license. Download as **Collada (.dae)** or **OBJ**.

```bash
# Extract the downloaded zip, then import
bash scripts/import_asset.sh my_dae_model /path/to/extracted/scene.dae 1
```

- [ ] Does the model load with its original colors/textures?
- [ ] If the model is grey (missing texture), check: `grep map_ meshes/*.mtl` — are those texture files in `meshes/`?
- [ ] If textures are in a subfolder, copy them alongside the mesh and re-test

---

### Task 5 — Examine the Ambulance model

The Ambulance is an `.obj` model already in the PX4 directory:

```bash
# Examine its structure
ls /home/az/PX4-Autopilot/Tools/simulation/gz/models/Ambulance/meshes/
cat /home/az/PX4-Autopilot/Tools/simulation/gz/models/Ambulance/model.sdf
grep "map_" /home/az/PX4-Autopilot/Tools/simulation/gz/models/Ambulance/meshes/ambulance.mtl
```

- [ ] What scale is used and why?
- [ ] Where does the `.mtl` say the texture is? Is that file there?
- [ ] Add the Ambulance to your `external_world.sdf` and run it — does the texture appear?

---

## 🔍 Self-Check Questions

1. What is the difference between `.stl` and `.dae` formats? When would you choose each?
2. Why does Gazebo fail to find a texture even though the texture file exists in the model folder?
3. A model downloads as `.fbx`. What do you do before importing it into Gazebo?
4. A model that is 5 metres tall in real life appears as 5 millimetres in Gazebo. What is the most likely source unit and what scale factor do you apply?
5. Why is it better to use a simple bounding box for collision instead of the full mesh?
6. What is the difference between using `model://ModelName/meshes/file.dae` vs `meshes/file.dae` as a URI — and where is each form used?
