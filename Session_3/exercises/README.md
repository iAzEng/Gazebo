# Session 03 — Exercise

## 🎯 Goal

Download assets from Gazebo Fuel, integrate them into a PX4 world, and run the simulation with the X500 drone.

---

## 📋 Tasks

### Task 1 — Download and place a model

Choose any model from [https://app.gazebosim.org/fuel/models](https://app.gazebosim.org/fuel/models) — pick something interesting to you (a building, vehicle, tree, obstacle).

```bash
# Download it (quote names with spaces)
gz fuel download -u "https://fuel.gazebosim.org/1.0/OWNER/models/NAME" -v 4

# Check the version number — it is not always 1
ls ~/.gz/fuel/fuel.gazebosim.org/OWNER_lowercase/models/name_lowercase/

# Copy contents to PX4 models directory (replace VERSION with the actual number)
# If the model name has spaces, use underscores for the destination folder
mkdir -p /home/az/PX4-Autopilot/Tools/simulation/gz/models/NAME
cp -r ~/.gz/fuel/fuel.gazebosim.org/OWNER_lowercase/models/name_lowercase/VERSION/. \
      /home/az/PX4-Autopilot/Tools/simulation/gz/models/NAME/
```

Verify:
- [ ] `model.sdf` exists in the folder
- [ ] `model.config` exists in the folder
- [ ] Run `cat model.sdf` — can you identify the links and visuals?

---

### Task 2 — Create a world that uses your model

Create a new world SDF file at:
```
/home/az/PX4-Autopilot/Tools/simulation/gz/worlds/my_fuel_world.sdf
```

Your world must include:
- [ ] **No** explicit `<plugin>` tags — plugins come from `server.config`, adding them will break PX4
- [ ] `<physics type="ode">` with `real_time_update_rate>250`
- [ ] `<gravity>`, `<magnetic_field>`, `<atmosphere>` elements
- [ ] `<spherical_coordinates>` block (copy from `fuel_world.sdf`)
- [ ] `<world name="my_fuel_world">` matching the filename stem exactly
- [ ] A sun light and ground plane
- [ ] Your downloaded Fuel model via `<include><uri>model://NAME</uri></include>`
- [ ] The model placed at a position away from origin (so drone doesn't spawn inside it)

> 💡 Use `fuel_world.sdf` from this session as your starting template — it already has the correct structure.

---

### Task 3 — Run with PX4

```bash
# Terminal 1
export GZ_SIM_RESOURCE_PATH=/home/az/PX4-Autopilot/Tools/simulation/gz/models
export GZ_SIM_SERVER_CONFIG_PATH=/home/az/.simulation-gazebo/server.config
export GZ_SIM_SYSTEM_PLUGIN_PATH=/home/az/PX4-Autopilot/build/px4_sitl_default/src/modules/simulation/gz_plugins
gz sim -r /home/az/PX4-Autopilot/Tools/simulation/gz/worlds/my_fuel_world.sdf

# Terminal 2 (only after Gazebo shows the world)
# PX4_GZ_WORLD must match <world name='...'> inside your SDF — set it to whatever you named the world
cd ~/PX4-Autopilot
PX4_GZ_STANDALONE=1 PX4_GZ_WORLD=my_fuel_world make px4_sitl gz_x500
```

- [ ] Does the drone spawn correctly?
- [ ] Is your Fuel model visible in Gazebo?
- [ ] Does QGroundControl connect?
- [ ] Can you arm and hover the drone near your model?

---

### Task 4 — Download and run a Fuel world

Find a complete world on [https://app.gazebosim.org/fuel/worlds](https://app.gazebosim.org/fuel/worlds).

```bash
# Download it
gz fuel download -u "https://fuel.gazebosim.org/1.0/OWNER/worlds/NAME" -v 4

# Check version number and world name inside the SDF
ls ~/.gz/fuel/fuel.gazebosim.org/OWNER_lowercase/worlds/name_lowercase/
grep "world name" ~/.gz/fuel/fuel.gazebosim.org/OWNER_lowercase/worlds/name_lowercase/VERSION/*.sdf

# Copy the SDF — the filename MUST match the <world name='...'> attribute inside
cp ~/.gz/fuel/fuel.gazebosim.org/OWNER_lowercase/worlds/name_lowercase/VERSION/*.sdf \
   /home/az/PX4-Autopilot/Tools/simulation/gz/worlds/WORLD_NAME.sdf
```

> ⚠️ Downloaded Fuel worlds almost always need the PX4 compatibility fixes from the "Making Any Gazebo World Work with PX4" section in the main README before they will work with the drone.

```bash
# Terminal 1
export GZ_SIM_RESOURCE_PATH=/home/az/PX4-Autopilot/Tools/simulation/gz/models
export GZ_SIM_SERVER_CONFIG_PATH=/home/az/.simulation-gazebo/server.config
export GZ_SIM_SYSTEM_PLUGIN_PATH=/home/az/PX4-Autopilot/build/px4_sitl_default/src/modules/simulation/gz_plugins
gz sim -r /home/az/PX4-Autopilot/Tools/simulation/gz/worlds/WORLD_NAME.sdf

# Terminal 2 (after Gazebo shows the world)
cd ~/PX4-Autopilot
PX4_GZ_STANDALONE=1 PX4_GZ_WORLD=WORLD_NAME make px4_sitl gz_x500
```

- [ ] Does the world load correctly?
- [ ] Are there any missing model errors? If yes, which models are missing?
- [ ] If the world is too heavy, open the SDF and remove some `<include>` blocks to lighten it

---

## 🔍 Self-Check Questions

1. What is the difference between using a Fuel URI directly in `<include>` vs downloading manually?
2. Why does the downloaded asset have a version subfolder (e.g. `/1/`, `/3/`), and what does it represent? Is it always `/1/`?
3. What does `GZ_SIM_RESOURCE_PATH` do, and what happens if it is not set?
4. A model shows as a grey box in Gazebo — what is the most likely cause?
5. You download a world from Fuel and it fails to load some models. How do you find out which models are missing?
6. What is the difference between `model://ModelName` and `https://fuel.gazebosim.org/...` as a URI?
