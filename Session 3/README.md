## 🎯 Learning Objectives

By the end of this session you will be able to:

- [ ] Browse and find worlds and models on Gazebo Fuel
- [ ] Download a model or world from Gazebo Fuel using the CLI
- [ ] Correctly place downloaded assets in the PX4 directories
- [ ] Reference a Fuel model inside a world SDF using `<include>`
- [ ] Run a custom Fuel world with the X500 drone using PX4 standalone mode
- [ ] Debug common path and resource issues

---

## 📚 Concepts Covered

### 1. What is Gazebo Fuel?

[Gazebo Fuel](https://app.gazebosim.org/fuel) is an online library of ready-made 3D models and worlds in SDF format. Everything on Fuel is already compatible with Gazebo Sim 8 — no conversion needed.

| Type | What it is | Example |
|------|-----------|---------|
| **Model** | A single 3D object (building, vehicle, obstacle) | Ambulance, Gas Station, Tree |
| **World** | A complete SDF world file (may include models) | Depot, Warehouse, Baylands |

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
└── models/        ← each model is a subfolder here
```

Each model must be a folder with this structure:
```
models/
└── ModelName/            ← folder name must match the <uri>
    ├── model.config      ← required metadata
    ├── model.sdf         ← the model definition
    └── meshes/           ← optional mesh files (.dae, .stl)
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
~/.gz/fuel/fuel.gazebosim.org/owner_lowercase/models/NAME/VERSION/
~/.gz/fuel/fuel.gazebosim.org/owner_lowercase/worlds/NAME/VERSION/
```

> ⚠️ **Important:** The owner name in the cache path is always **lowercase**, regardless of how it appears in the URL. Also, Fuel assigns a version number to every asset (e.g. `/4/`). Always check the actual version number before copying:
> ```bash
> ls ~/.gz/fuel/fuel.gazebosim.org/openrobotics/models/ambulance/
> # might show: 4   (not necessarily 1)
> ```

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

### 6. A Note on PX4_GZ_WORLD

`PX4_GZ_WORLD` is an environment variable that sets the world for PX4's **normal make mode** (e.g. `PX4_GZ_WORLD=baylands make px4_sitl gz_x500`). It only works with worlds that are registered inside PX4's CMakeLists and stored in the PX4 worlds directory.

For external Fuel worlds we always use **standalone mode** (`gz sim` + `PX4_GZ_STANDALONE=1`), which bypasses this limitation entirely. This is the correct approach for custom worlds in this and future sessions.

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

We will use the **Ambulance** model by OpenRobotics as our example.

#### Step 2 — Download the model

```bash
gz fuel download -u https://fuel.gazebosim.org/1.0/OpenRobotics/models/Ambulance -v 4
```

Now check what version was downloaded (the folder name is the version number):

```bash
ls ~/.gz/fuel/fuel.gazebosim.org/openrobotics/models/ambulance/
```

Note the version number shown (e.g. `4`), then verify its contents:

```bash
ls ~/.gz/fuel/fuel.gazebosim.org/openrobotics/models/ambulance/4/
# Expected: materials  meshes  model.config  model.sdf  thumbnails
```

#### Step 3 — Create the destination folder and copy

First create the destination folder, then copy the model contents into it:

```bash
mkdir -p /home/az/PX4-Autopilot/Tools/simulation/gz/models/Ambulance
```

```bash
cp -r ~/.gz/fuel/fuel.gazebosim.org/openrobotics/models/ambulance/4/. \
      /home/az/PX4-Autopilot/Tools/simulation/gz/models/Ambulance/
```

> The `/4/.` at the end means "copy the **contents** of the version folder", not the folder itself. Replace `4` with your actual version number if different.

Verify the result:
```bash
ls /home/az/PX4-Autopilot/Tools/simulation/gz/models/Ambulance/
# Expected: materials  meshes  model.config  model.sdf  thumbnails
```

#### Step 4 — Inspect the model SDF

```bash
cat /home/az/PX4-Autopilot/Tools/simulation/gz/models/Ambulance/model.sdf
```

Identify the links, visuals, and collision shapes — same structure as Session 1.

#### Step 5 — Launch Gazebo with the example world

> ⚠️ **Order matters:** Always start Gazebo first and wait until the world is fully loaded before running PX4. Starting PX4 too early causes a timeout error.

**Terminal 1 — Start Gazebo and wait for it to fully load:**
```bash
export GZ_SIM_RESOURCE_PATH=/home/az/PX4-Autopilot/Tools/simulation/gz/models:/home/az/PX4-Autopilot/Tools/simulation/gz/models/Ambulance/materials/textures
gz sim /home/az/PX4-Autopilot/Tools/simulation/gz/worlds/fuel_world.sdf
```

Wait until the Gazebo GUI appears and the world is rendered. Then press ▶️ **Play**.

**Terminal 2 — Start PX4 after Gazebo is fully loaded:**
```bash
cd ~/PX4-Autopilot
PX4_GZ_STANDALONE=1 make px4_sitl gz_x500
```

The drone spawns in the world alongside the Ambulance model. Connect QGroundControl and verify.

---

### Part 2 — Download and Run a Full Fuel World

#### Step 1 — Browse Fuel worlds

Go to [https://app.gazebosim.org/fuel/worlds](https://app.gazebosim.org/fuel/worlds)

We will use the **Depot** world by OpenRobotics.

#### Step 2 — Download the world

```bash
gz fuel download -u https://fuel.gazebosim.org/1.0/OpenRobotics/worlds/Depot -v 4
```

Check the version number:
```bash
ls ~/.gz/fuel/fuel.gazebosim.org/openrobotics/worlds/depot/
```

#### Step 3 — Inspect the world SDF

```bash
ls ~/.gz/fuel/fuel.gazebosim.org/openrobotics/worlds/depot/1/
cat ~/.gz/fuel/fuel.gazebosim.org/openrobotics/worlds/depot/1/*.sdf
```

Check which models it includes from Fuel:
```bash
grep -i "fuel.gazebosim.org" ~/.gz/fuel/fuel.gazebosim.org/openrobotics/worlds/depot/1/*.sdf
```

Any `<uri>` pointing to `fuel.gazebosim.org` will auto-download on first run if you have internet.

#### Step 4 — Copy the world SDF to PX4

```bash
cp ~/.gz/fuel/fuel.gazebosim.org/openrobotics/worlds/depot/1/*.sdf \
   /home/az/PX4-Autopilot/Tools/simulation/gz/worlds/depot.sdf
```

#### Step 5 — Run with PX4

**Terminal 1 — Start Gazebo and wait for it to fully load:**
```bash
export GZ_SIM_RESOURCE_PATH=/home/az/PX4-Autopilot/Tools/simulation/gz/models
gz sim /home/az/PX4-Autopilot/Tools/simulation/gz/worlds/depot.sdf
```

Wait until the GUI appears and the world is rendered. Then press ▶️ **Play**.

**Terminal 2 — Start PX4 after Gazebo is fully loaded:**
```bash
cd ~/PX4-Autopilot
PX4_GZ_STANDALONE=1 make px4_sitl gz_x500
```

---

## ❓ Common Issues & Debugging

**`ERROR [init] Timed out waiting for Gazebo world`**
- You ran PX4 before Gazebo finished loading
- Always wait for the Gazebo GUI to fully appear and press ▶️ Play before running Terminal 2

**`Unable to find uri[model://ModelName]`**
- Model is not in `GZ_SIM_RESOURCE_PATH`
- Run `echo $GZ_SIM_RESOURCE_PATH` to verify it is set
- Folder name must exactly match the `<uri>` — case-sensitive

**`Could not resolve file [ambulance.png]` or similar:**
- The model has material/texture files that reference relative paths
- Make sure you copied the full contents of the version folder including `materials/` and `meshes/`

**Downloaded version number is not `/1/`:**
- The Fuel cache uses the model's actual version number (could be `/2/`, `/4/`, etc.)
- Always run `ls ~/.gz/fuel/.../models/modelname/` first to find the correct number

**Wrong folder structure after copying:**
- If you see a version number subfolder (e.g. `Ambulance/4/model.sdf`) you copied the folder instead of its contents
- Fix: `cp -r ~/.gz/fuel/.../ambulance/4/. /path/to/models/Ambulance/` (note the `/.` at the end)

**World runs but is very heavy / low FPS:**
- Open the world SDF and remove decorative `<include>` model blocks
- Keep only: Physics, UserCommands, SceneBroadcaster plugins

---

## 🔗 References

- [Gazebo Fuel](https://app.gazebosim.org/fuel)
- [Gazebo Fuel CLI](https://gazebosim.org/api/fuel_tools/9/cmdline.html)
- [Gazebo: Model Insertion from Fuel](https://gazebosim.org/docs/harmonic/fuel_insert/)
- [PX4 Gazebo Models](https://docs.px4.io/main/en/sim_gazebo_gz/gazebo_models.html)
