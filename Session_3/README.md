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
/home/YOUR_NAME/PX4-Autopilot/Tools/simulation/gz/
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
~/.gz/fuel/fuel.gazebosim.org/owner_lowercase/models/name_lowercase/VERSION/
~/.gz/fuel/fuel.gazebosim.org/owner_lowercase/worlds/name_lowercase/VERSION/
```

Owner and model names are stored **lowercase** in the cache. The version number at the end is usually `1` but can be higher — always run `ls` on the model folder to confirm the actual version before copying.

### 5. GZ_SIM_RESOURCE_PATH

Tells Gazebo where to search for models when it encounters `model://ModelName` in an SDF file.

```bash
export GZ_SIM_RESOURCE_PATH=/home/YOUR_NAME/PX4-Autopilot/Tools/simulation/gz/models
```

Add permanently to `~/.bashrc` if not done already:
```bash
echo 'export GZ_SIM_RESOURCE_PATH=/home/YOUR_NAME/PX4-Autopilot/Tools/simulation/gz/models' >> ~/.bashrc
source ~/.bashrc
```

### 6. PX4-Compatible World Structure

**Session 1 worlds vs PX4-integrated worlds are structured differently.**

| Element | Session 1 (standalone Gazebo) | Session 3+ (PX4-integrated) |
|---------|------------------------------|----------------------------|
| `<gravity>` | Optional | Required — needed by IMU and physics |
| `<magnetic_field>` | Not used | Required — needed by magnetometer sensor |
| `<atmosphere>` | Not used | Required — needed by barometer sensor |
| `<spherical_coordinates>` | Not used | **Required** — defines GPS home position. Without it PX4 cannot connect. |
| Physics type | `"ignored"` (Gazebo default) | `"ode"` with `real_time_update_rate>250` |

**Requirement 1 — Start Gazebo first, then PX4.**
PX4 connects to an already-running Gazebo server. Terminal 2 must only start after Terminal 1 shows the Gazebo window.

**Requirement 2 — Use `gz sim -r` (not just `gz sim`).**
Without `-r`, Gazebo starts paused. PX4 waits for the world clock to tick — which never happens until Play is pressed. The `-r` flag starts the world immediately.

**Requirement 3 — Set `GZ_SIM_SERVER_CONFIG_PATH`.**
All plugins (Physics, SceneBroadcaster, IMU, GPS, barometer, magnetometer) must come from `server.config`, not from the SDF. If the SDF has explicit plugins AND `server.config` loads the same plugins, they load twice and physics breaks silently.

```bash
export GZ_SIM_SERVER_CONFIG_PATH=/home/YOUR_NAME/.simulation-gazebo/server.config
```

**Requirement 4 — Set `PX4_GZ_WORLD` to match the `<world name='...'>` attribute.**
In standalone mode, PX4 skips automatic world discovery. It uses `PX4_GZ_WORLD` to construct Gazebo service paths (`/world/<name>/scene/info`, etc.). Without it the world name is empty, every service call fails, and PX4 exits after 30 seconds.

```bash
PX4_GZ_STANDALONE=1 PX4_GZ_WORLD=fuel_world make px4_sitl gz_x500
```

**Requirement 5 — (Optional) Set `GZ_SIM_SYSTEM_PLUGIN_PATH` to silence `[Err]` warnings.**
`server.config` references two optional PX4 camera plugins. Gazebo cannot find them without this path — it logs errors but continues. Set this to eliminate the noise:

```bash
export GZ_SIM_SYSTEM_PLUGIN_PATH=/home/YOUR_NAME/PX4-Autopilot/build/px4_sitl_default/src/modules/simulation/gz_plugins
```

The `~/.simulation-gazebo/` directory is created by running the PX4 `simulation-gazebo` setup script. If it does not exist:
```bash
wget https://raw.githubusercontent.com/PX4/PX4-gazebo-models/main/simulation-gazebo
python3 ~/simulation-gazebo --world default
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

We will use the **Construction Cone** model by OpenRobotics:
`https://fuel.gazebosim.org/1.0/OpenRobotics/models/Construction Cone`

Note the URL structure: `fuel.gazebosim.org/1.0/<owner>/models/<name>`

#### Step 2 — Download the model

Model names with spaces must be quoted in the shell:

```bash
gz fuel download -u "https://fuel.gazebosim.org/1.0/OpenRobotics/models/Construction Cone" -v 4
```

Check what version was downloaded (version numbers are not always `1`):
```bash
ls ~/.gz/fuel/fuel.gazebosim.org/openrobotics/models/construction\ cone/
```

Fuel stores model names in **lowercase** in the cache. The version number is the folder inside (e.g. `3` for Construction Cone — yours may differ).

#### Step 3 — Copy to PX4 models directory

We rename the folder using an underscore so it can be used as a `model://` URI without spaces.

Use the version number you found in Step 2 (replace `3` if yours was different):

```bash
mkdir -p /home/YOUR_NAME/PX4-Autopilot/Tools/simulation/gz/models/Construction_Cone
cp -r ~/.gz/fuel/fuel.gazebosim.org/openrobotics/models/construction\ cone/3/. \
      /home/YOUR_NAME/PX4-Autopilot/Tools/simulation/gz/models/Construction_Cone/
```

Note the `3/.` — this copies the **contents** of the version folder, not the folder itself. Replace `3` with the actual version number from Step 2.

Verify structure:
```bash
ls /home/YOUR_NAME/PX4-Autopilot/Tools/simulation/gz/models/Construction_Cone/
# Expected: model.config  model.sdf  meshes/
```

#### Step 4 — Inspect the model SDF

```bash
cat /home/YOUR_NAME/PX4-Autopilot/Tools/simulation/gz/models/Construction_Cone/model.sdf
```

Identify the links, visuals, and collision shapes — same structure as Session 1.

#### Step 5 — Run the example world

First, copy the world file into PX4's worlds directory (one-time setup):

```bash
cp /home/YOUR_NAME/Videos/Session_3/worlds/fuel_world.sdf \
   /home/YOUR_NAME/PX4-Autopilot/Tools/simulation/gz/worlds/fuel_world.sdf
```

Then launch in two terminals:

```bash
# Terminal 1
export GZ_SIM_RESOURCE_PATH=/home/YOUR_NAME/PX4-Autopilot/Tools/simulation/gz/models
export GZ_SIM_SERVER_CONFIG_PATH=/home/YOUR_NAME/.simulation-gazebo/server.config
export GZ_SIM_SYSTEM_PLUGIN_PATH=/home/YOUR_NAME/PX4-Autopilot/build/px4_sitl_default/src/modules/simulation/gz_plugins
gz sim -r /home/YOUR_NAME/PX4-Autopilot/Tools/simulation/gz/worlds/fuel_world.sdf
```

Wait until the Gazebo window is showing the world, then start Terminal 2:

```bash
# Terminal 2
# PX4_GZ_WORLD must match the <world name='...'> attribute inside fuel_world.sdf
cd ~/PX4-Autopilot
PX4_GZ_STANDALONE=1 PX4_GZ_WORLD=fuel_world make px4_sitl gz_x500
```

The drone spawns in the world alongside the Construction Cone model.

---

### Part 2 — Download and Run a Full Fuel World

#### Step 1 — Browse Fuel worlds

Go to [https://app.gazebosim.org/fuel/worlds](https://app.gazebosim.org/fuel/worlds)

We will use the **husky_depot** world by MovAi.

#### Step 2 — Download the world

```bash
gz fuel download -u https://fuel.gazebosim.org/1.0/MovAi/worlds/husky_depot -v 4
```

#### Step 3 — Inspect it

Fuel stores world names lowercase. Check the version number first (it may not be `1`):

```bash
ls ~/.gz/fuel/fuel.gazebosim.org/movai/worlds/husky_depot/
```

Then inspect using the actual version number (replace `1` if yours differs):

```bash
ls ~/.gz/fuel/fuel.gazebosim.org/movai/worlds/husky_depot/1/
cat ~/.gz/fuel/fuel.gazebosim.org/movai/worlds/husky_depot/1/*.sdf
```

Check what models it includes:
```bash
grep -i "fuel.gazebosim.org" ~/.gz/fuel/fuel.gazebosim.org/movai/worlds/husky_depot/1/*.sdf
```

Any `<include>` with a Fuel URI will auto-download on first run.

#### Step 4 — Check the world name and copy to PX4 worlds directory

The world name inside the SDF must match the filename stem and must match `PX4_GZ_WORLD`:

```bash
# Check what <world name='...'> is set to inside the downloaded file
# (replace /1/ with your actual version number from Step 3)
grep "world name" ~/.gz/fuel/fuel.gazebosim.org/movai/worlds/husky_depot/1/*.sdf

# Copy to PX4 worlds directory — filename must match the world name attribute
cp ~/.gz/fuel/fuel.gazebosim.org/movai/worlds/husky_depot/1/*.sdf \
   /home/YOUR_NAME/PX4-Autopilot/Tools/simulation/gz/worlds/husky_depot.sdf
```

> ⚠️ Downloaded Fuel worlds often need the PX4 compatibility fixes described in the [Making Any Gazebo World Work with PX4](#-making-any-gazebo-world-work-with-px4) section below before they will run with the drone.

#### Step 5 — Run with PX4

```bash
# Terminal 1
export GZ_SIM_RESOURCE_PATH=/home/YOUR_NAME/PX4-Autopilot/Tools/simulation/gz/models
export GZ_SIM_SERVER_CONFIG_PATH=/home/YOUR_NAME/.simulation-gazebo/server.config
export GZ_SIM_SYSTEM_PLUGIN_PATH=/home/YOUR_NAME/PX4-Autopilot/build/px4_sitl_default/src/modules/simulation/gz_plugins
gz sim -r /home/YOUR_NAME/PX4-Autopilot/Tools/simulation/gz/worlds/husky_depot.sdf

# Terminal 2 (after Terminal 1 shows the world is running)
# Replace "husky_depot" with the actual world name you found in Step 4
cd ~/PX4-Autopilot
PX4_GZ_STANDALONE=1 PX4_GZ_WORLD=husky_depot make px4_sitl gz_x500
```

---

## ❓ Common Issues & Debugging

**PX4 keeps printing `Waiting for Gazebo world...` and then times out:**
- `PX4_GZ_WORLD` is not set or does not match the world name — this is the most common cause in standalone mode. PX4 calls `/world/<name>/scene/info`; if `PX4_GZ_WORLD` is empty, the path is `/world//scene/info` which always fails. Use `PX4_GZ_STANDALONE=1 PX4_GZ_WORLD=<world_name> make px4_sitl gz_x500`
- You forgot the `-r` flag — without it Gazebo starts paused and PX4 waits for clock ticks
- You started Terminal 2 before Gazebo had fully loaded
- `GZ_SIM_SERVER_CONFIG_PATH` is not set — sensor plugins won't load and PX4 cannot operate the drone

**`Unable to find uri[model://ModelName]`**
- Model is not in `GZ_SIM_RESOURCE_PATH`
- Run `echo $GZ_SIM_RESOURCE_PATH` to verify it is set
- Folder name must exactly match the name in `<uri>` — case-sensitive

**Model is grey box or invisible:**
- Missing mesh files — check if `meshes/` folder exists in the model
- The SDF may reference a `.dae` or `.stl` that wasn't downloaded

**Copied the wrong folder level:**
- Fuel downloads put assets inside a version subfolder (e.g. `/1/`, `/3/`) — check with `ls` first
- Always `mkdir -p` the destination, then copy the **contents** using `VERSION/.`:
  ```bash
  # Check actual version first
  ls ~/.gz/fuel/.../modelname/
  # Correct — copies contents of version folder:
  mkdir -p /path/to/models/ModelName
  cp -r ~/.gz/fuel/.../modelname/VERSION/. /path/to/models/ModelName/
  # Wrong — copies the version folder itself as ModelName:
  cp -r ~/.gz/fuel/.../modelname/VERSION /path/to/models/ModelName
  ```

**World runs but is very heavy / low FPS:**
- Open the world SDF and remove decorative `<include>` models (trees, props)
- Do not add explicit `<plugin>` tags — all required plugins come from `server.config`

**Fuel world has internal model URIs that fail:**
- Some worlds reference their own models by `model://` — those models must also be in `GZ_SIM_RESOURCE_PATH`
- Download each referenced model and copy to the PX4 models directory

**`[Err] Failed to load system plugin [libOpticalFlowSystem.so]` / `[libGstCameraSystem.so]`:**
- These are **non-fatal warnings** — Gazebo continues loading and the simulation runs correctly
- They appear because `server.config` lists these two optional PX4 camera plugins, but Gazebo cannot find them without `GZ_SIM_SYSTEM_PLUGIN_PATH` set
- `libOpticalFlowSystem.so` is used only with optical-flow targets (e.g. `gz_x500_flow`); `libGstCameraSystem.so` is used only when a GStreamer camera model is spawned — neither is needed for basic X500 flight
- To silence them, add to Terminal 1 (requires PX4 to have been built at least once):
  ```bash
  export GZ_SIM_SYSTEM_PLUGIN_PATH=/home/YOUR_NAME/PX4-Autopilot/build/px4_sitl_default/src/modules/simulation/gz_plugins
  ```

---

## 🔧 Making Any Gazebo World Work with PX4

### Why downloaded worlds often fail

A world downloaded from Gazebo Fuel (or found online) is built for *standalone* Gazebo use. It typically carries its own `<plugin>` tags to load Physics and rendering, uses no GPS frame, omits the magnetometer and barometer data fields PX4 needs, and may have a `<world name>` that does not match the filename PX4 uses to address it. Dropping such a file into PX4's worlds directory and running it will usually produce one or more of the following failures:

- PX4 exits with `ERROR [init] Timed out waiting for Gazebo world` — GPS/sensor plugins are absent, `PX4_GZ_WORLD` is not set, or PX4 cannot match the world name
- EKF divergence / arming refused — physics rate wrong or gravity/magnetic field missing
- Physics behaves strangely with no error message — a plugin loaded twice because the SDF still contains `<plugin>` tags that duplicate what `server.config` already loads

The checklist below fixes all of these systematically.

---

### Checklist — adapting a Fuel world for PX4

#### 1. World name must match the SDF filename stem

The `<world name='...'>` attribute must equal the filename without the `.sdf` extension, with no spaces.

```xml
<!-- File: my_world.sdf -->

<!-- Before (whatever Fuel set): -->
<world name="Depot">

<!-- After: -->
<world name="my_world">
```

**Why:** PX4 builds every Gazebo topic and service path as `/world/<name>/...`. In standalone mode you pass the world name via `PX4_GZ_WORLD=<name>`. If the attribute does not match, all topic subscriptions fail silently.

#### 2. Remove all `<plugin>` tags (if you will use Standalone mode, otherwise do not remove it)

```xml
<!-- Before — delete every block like this: -->
<plugin filename="gz-sim-physics-system" name="gz::sim::systems::Physics"/>
<plugin filename="gz-sim-scene-broadcaster-system" name="gz::sim::systems::SceneBroadcaster"/>
<!-- ... and any others -->

<!-- After: no <plugin> elements anywhere inside <world> -->
```

**Why:** `server.config` already loads Physics, SceneBroadcaster, IMU, NavSat, Magnetometer, AirPressure, and others for every world. Duplicating Physics causes the simulation step to break silently.

#### 3. Add or verify `<physics>` with the correct rate

```xml
<!-- Before (common Fuel default): -->
<physics name="1ms" type="ignored">
  <max_step_size>0.001</max_step_size>
</physics>

<!-- After: -->
<physics type="ode">
  <max_step_size>0.004</max_step_size>
  <real_time_factor>1.0</real_time_factor>
  <real_time_update_rate>250</real_time_update_rate>
</physics>
```

**Why:** PX4's IMU integration runs at 250 Hz. A lower `real_time_update_rate` produces fewer sensor ticks than PX4 expects, causing EKF divergence and arming failures.

#### 4. Add `<gravity>`, `<magnetic_field>`, and `<atmosphere>`

```xml
<gravity>0 0 -9.8</gravity>
<magnetic_field>6e-06 2.3e-05 -4.2e-05</magnetic_field>
<atmosphere type="adiabatic"/>
```

**Why:**
- `<gravity>` — required by the Physics system and the IMU plugin
- `<magnetic_field>` — required by the Magnetometer plugin; without it compass initialization fails
- `<atmosphere>` — required by the AirPressure (barometer) plugin; without it altitude estimation fails

#### 5. Add `<spherical_coordinates>`

```xml
<spherical_coordinates>
  <surface_model>EARTH_WGS84</surface_model>
  <world_frame_orientation>ENU</world_frame_orientation>
  <latitude_deg>47.397971057728974</latitude_deg>
  <longitude_deg>8.546163739800146</longitude_deg>
  <elevation>0</elevation>
</spherical_coordinates>
```

**Why:** The NavSat/GPS plugin uses this to convert ENU simulation coordinates into WGS84 lat/lon/alt. Without it PX4 reports no GPS fix and refuses to arm in position modes.

#### 6. Set the three environment variables before launching

```bash
export GZ_SIM_RESOURCE_PATH=/home/YOUR_NAME/PX4-Autopilot/Tools/simulation/gz/models
export GZ_SIM_SERVER_CONFIG_PATH=/home/YOUR_NAME/.simulation-gazebo/server.config
export GZ_SIM_SYSTEM_PLUGIN_PATH=/home/YOUR_NAME/PX4-Autopilot/build/px4_sitl_default/src/modules/simulation/gz_plugins
```

- `GZ_SIM_RESOURCE_PATH` — resolves `model://` URIs in `<include>` blocks
- `GZ_SIM_SERVER_CONFIG_PATH` — loads the PX4 sensor plugin suite
- `GZ_SIM_SYSTEM_PLUGIN_PATH` — allows Gazebo to find the PX4-built optional plugins (silences the `[Err]` warnings)

#### 7. Use the correct launch commands

```bash
# Terminal 1
gz sim -r /home/YOUR_NAME/PX4-Autopilot/Tools/simulation/gz/worlds/my_world.sdf

# Terminal 2 (only after Gazebo window is visible)
# PX4_GZ_WORLD must match the <world name='...'> value inside the SDF
cd ~/PX4-Autopilot
PX4_GZ_STANDALONE=1 PX4_GZ_WORLD=my_world make px4_sitl gz_x500
```

**Why `PX4_GZ_WORLD` is required:** In standalone mode, PX4 skips automatic world discovery. It uses `PX4_GZ_WORLD` to construct all Gazebo service paths (`/world/<name>/...`). Without it the world name is empty, every service call fails, and PX4 exits after 30 seconds.

---

### PX4-compatible world skeleton

Copy this as a starting point when adapting any downloaded world. Replace `my_world` and the filename together.

```xml
<?xml version="1.0" ?>
<!-- File: my_world.sdf -->
<sdf version="1.9">
  <world name="my_world">

    <physics type="ode">
      <max_step_size>0.004</max_step_size>
      <real_time_factor>1.0</real_time_factor>
      <real_time_update_rate>250</real_time_update_rate>
    </physics>

    <gravity>0 0 -9.8</gravity>
    <magnetic_field>6e-06 2.3e-05 -4.2e-05</magnetic_field>
    <atmosphere type="adiabatic"/>

    <spherical_coordinates>
      <surface_model>EARTH_WGS84</surface_model>
      <world_frame_orientation>ENU</world_frame_orientation>
      <latitude_deg>47.397971057728974</latitude_deg>
      <longitude_deg>8.546163739800146</longitude_deg>
      <elevation>0</elevation>
    </spherical_coordinates>

    <!-- NO <plugin> tags — all plugins come from server.config -->

    <light name="sunUTC" type="directional">
      <pose>0 0 500 0 0 0</pose>
      <cast_shadows>true</cast_shadows>
      <intensity>1</intensity>
      <direction>0.001 0.625 -0.78</direction>
      <diffuse>0.904 0.904 0.904 1</diffuse>
      <specular>0.271 0.271 0.271 1</specular>
      <attenuation>
        <range>2000</range><linear>0</linear><constant>1</constant><quadratic>0</quadratic>
      </attenuation>
    </light>

    <model name="ground_plane">
      <static>true</static>
      <link name="link">
        <collision name="collision">
          <geometry><plane><normal>0 0 1</normal><size>1 1</size></plane></geometry>
          <surface><friction><ode/></friction><bounce/><contact/></surface>
        </collision>
        <visual name="visual">
          <geometry><plane><normal>0 0 1</normal><size>500 500</size></plane></geometry>
          <material>
            <ambient>0.8 0.8 0.8 1</ambient>
            <diffuse>0.8 0.8 0.8 1</diffuse>
            <specular>0.1 0.1 0.1 1</specular>
          </material>
        </visual>
      </link>
    </model>

    <!-- Add your <include> blocks or inline models here -->

  </world>
</sdf>
```

---

## 🔗 References

- [Gazebo Fuel](https://app.gazebosim.org/fuel)
- [Gazebo Fuel CLI](https://gazebosim.org/api/fuel_tools/9/cmdline.html)
- [Gazebo: Model Insertion from Fuel](https://gazebosim.org/docs/harmonic/fuel_insert/)
- [PX4 Gazebo Models](https://docs.px4.io/main/en/sim_gazebo_gz/gazebo_models.html)
