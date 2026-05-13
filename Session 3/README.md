## 🎯 Learning Objectives

By the end of this session you will be able to:

- [ ] Browse and find worlds and models on Gazebo Fuel
- [ ] Download a model from Gazebo Fuel using the CLI
- [ ] Download a world from Gazebo Fuel using the CLI
- [ ] Place downloaded assets in the correct PX4 directories
- [ ] Reference a Fuel model inside a world SDF using `<include>`
- [ ] Run a custom Fuel world with the X500 drone using PX4
- [ ] Debug common path and resource issues

---

## 📚 Concepts Covered

### 1. What is Gazebo Fuel?

[Gazebo Fuel](https://app.gazebosim.org/fuel) is an online library of ready-made 3D models and worlds in SDF format. Everything on Fuel is already compatible with Gazebo Sim 8 — no conversion needed.

| Type | What it is | Example |
|------|-----------|---------|
| **Model** | A single 3D object (building, tree, vehicle, obstacle) | Ambulance, Gas Station, Tree |
| **World** | A complete SDF world file (may include models inside) | Depot, Warehouse, Baylands |

### 2. Two Ways to Use Fuel Assets

**Method A — Online URI (runtime download):**

Add a `<include>` tag with the Fuel URL directly in your SDF. Gazebo downloads and caches it at `~/.gz/fuel/` on first run.

```xml
<include>
  <uri>https://fuel.gazebosim.org/1.0/OpenRobotics/models/Coke</uri>
  <name>coke_can_1</name>
  <pose>5 0 0 0 0 0</pose>
</include>
```

✅ Simple — no manual steps  
⚠️ Requires internet on first run

**Method B — Download manually, use locally:**

Download with `gz fuel download`, copy to PX4 models directory, reference by folder name.

✅ Works offline after download  
✅ Assets are inspectable and editable  
✅ Prepares you for Session 4 (external formats)

**We use Method B in this session.**

### 3. PX4 Directory Structure

```
/home/az/PX4-Autopilot/Tools/simulation/gz/
├── worlds/        ← world .sdf files go here
└── models/        ← model folders go here
```

Each model must be a folder following this structure:
```
models/
└── ModelName/            ← folder name must match the uri
    ├── model.config      ← required metadata file
    ├── model.sdf         ← the model definition
    └── meshes/           ← optional mesh files
```

The `model.config` file (required by Gazebo):
```xml
<?xml version="1.0"?>
<model>
  <name>Model Name</name>
  <version>1.0</version>
  <sdf version="1.10">model.sdf</sdf>
  <description>Brief description</description>
</model>
```

### 4. The gz fuel CLI

```bash
# Download a model
gz fuel download -u https://fuel.gazebosim.org/1.0/OWNER/models/NAME -v 4

# Download a world
gz fuel download -u https://fuel.gazebosim.org/1.0/OWNER/worlds/NAME -v 4
```

`-v 4` gives verbose output. Assets download to:
```
~/.gz/fuel/fuel.gazebosim.org/OWNER/models/NAME/1/
~/.gz/fuel/fuel.gazebosim.org/OWNER/worlds/NAME/1/
```

Note the `/1/` at the end — that is the version folder. When copying to PX4, copy the **contents** of `/1/`, not the `/1/` folder itself.

### 5. GZ_SIM_RESOURCE_PATH

Tells Gazebo where to search for models when it encounters `model://ModelName` in an SDF file.

```bash
export GZ_SIM_RESOURCE_PATH=/home/az/PX4-Autopilot/Tools/simulation/gz/models
```

Add permanently to `~/.bashrc` if not done already:
```bash
echo 'export GZ_SIM_RESOURCE_PATH=/home/az/PX4-Autopilot/Tools/simulation/gz/models' >> ~/.bashrc
source ~/.bashrc
```

---

## 📂 Files in This Session

```
gaz/
├── README.md
├── worlds/
│   └── fuel_world.sdf       ← example world using a Fuel model
├── scripts/
│   └── download_fuel.sh     ← helper to download from Fuel
└── exercises/
    └── README.md
```

---

## 🛠️ Guided Walkthrough

### Part 1 — Add a Fuel Model to a World

#### Step 1 — Browse Gazebo Fuel

Go to [https://app.gazebosim.org/fuel/models](https://app.gazebosim.org/fuel/models) and browse.

We will use the **Ambulance** model by OpenRobotics:
`https://fuel.gazebosim.org/1.0/OpenRobotics/models/Ambulance`

Note the URL structure: `fuel.gazebosim.org/1.0/<owner>/models/<name>`

#### Step 2 — Download the model

```bash
gz fuel download -u https://fuel.gazebosim.org/1.0/OpenRobotics/models/Ambulance -v 4
```

Verify it downloaded:
```bash
ls ~/.gz/fuel/fuel.gazebosim.org/openrobotics/models/Ambulance/1/
```

#### Step 3 — Copy to PX4 models directory

```bash
cp -r ~/.gz/fuel/fuel.gazebosim.org/openrobotics/models/Ambulance/1 \
      /home/az/PX4-Autopilot/Tools/simulation/gz/models/Ambulance
```

Verify structure:
```bash
ls /home/az/PX4-Autopilot/Tools/simulation/gz/models/Ambulance/
# Expected: model.config  model.sdf  (and possibly meshes/)
```

#### Step 4 — Inspect the model SDF

```bash
cat /home/az/PX4-Autopilot/Tools/simulation/gz/models/Ambulance/model.sdf
```

Identify the links, visuals, and collision shapes — same structure as Session 1.

#### Step 5 — Run the example world

```bash
# Terminal 1
export GZ_SIM_RESOURCE_PATH=/home/az/PX4-Autopilot/Tools/simulation/gz/models
gz sim /home/az/PX4-Autopilot/Tools/simulation/gz/worlds/fuel_world.sdf

# Terminal 2
cd ~/PX4-Autopilot
PX4_GZ_STANDALONE=1 make px4_sitl gz_x500
```

The drone spawns in the world alongside the Ambulance model.

---

### Part 2 — Download and Run a Full Fuel World

#### Step 1 — Browse Fuel worlds

Go to [https://app.gazebosim.org/fuel/worlds](https://app.gazebosim.org/fuel/worlds)

We will use the **Depot** world by OpenRobotics.

#### Step 2 — Download the world

```bash
gz fuel download -u https://fuel.gazebosim.org/1.0/OpenRobotics/worlds/Depot -v 4
```

#### Step 3 — Inspect it

```bash
ls ~/.gz/fuel/fuel.gazebosim.org/openrobotics/worlds/Depot/1/
cat ~/.gz/fuel/fuel.gazebosim.org/openrobotics/worlds/Depot/1/*.sdf
```

Check what models it includes:
```bash
grep -i "fuel.gazebosim.org" ~/.gz/fuel/fuel.gazebosim.org/openrobotics/worlds/Depot/1/*.sdf
```

Any `<include>` with a Fuel URI will auto-download on first run.

#### Step 4 — Copy to PX4 worlds directory

```bash
cp ~/.gz/fuel/fuel.gazebosim.org/openrobotics/worlds/Depot/1/depot.sdf \
   /home/az/PX4-Autopilot/Tools/simulation/gz/worlds/depot.sdf
```

#### Step 5 — Run with PX4

```bash
# Terminal 1
export GZ_SIM_RESOURCE_PATH=/home/az/PX4-Autopilot/Tools/simulation/gz/models
gz sim /home/az/PX4-Autopilot/Tools/simulation/gz/worlds/depot.sdf

# Terminal 2
cd ~/PX4-Autopilot
PX4_GZ_STANDALONE=1 make px4_sitl gz_x500
```

---

## ❓ Common Issues & Debugging

**`Unable to find uri[model://ModelName]`**
- Model is not in `GZ_SIM_RESOURCE_PATH`
- Run `echo $GZ_SIM_RESOURCE_PATH` to verify it is set
- Folder name must exactly match the name in `<uri>` — case-sensitive

**Model is grey box or invisible:**
- Missing mesh files — check if `meshes/` folder exists in the model
- The SDF may reference a `.dae` or `.stl` that wasn't downloaded

**Copied the wrong folder level:**
- Fuel downloads put assets inside a version subfolder `/1/`
- Copy the contents of `/1/` not `/1/` itself:
  ```bash
  # Correct:
  cp -r ~/.gz/fuel/.../ModelName/1 /path/to/models/ModelName
  # Wrong:
  cp -r ~/.gz/fuel/.../ModelName /path/to/models/
  ```

**World runs but is very heavy / low FPS:**
- Open the world SDF and remove decorative `<include>` models (trees, props)
- Comment out non-essential plugins
- Keep only: Physics, UserCommands, SceneBroadcaster

**Fuel world has internal model URIs that fail:**
- Some worlds reference their own models by `model://` — those models must also be in `GZ_SIM_RESOURCE_PATH`
- Download each referenced model and copy to the PX4 models directory

---

## 🔗 References

- [Gazebo Fuel](https://app.gazebosim.org/fuel)
- [Gazebo Fuel CLI](https://gazebosim.org/api/fuel_tools/9/cmdline.html)
- [Gazebo: Model Insertion from Fuel](https://gazebosim.org/docs/harmonic/fuel_insert/)
- [PX4 Gazebo Models](https://docs.px4.io/main/en/sim_gazebo_gz/gazebo_models.html)
