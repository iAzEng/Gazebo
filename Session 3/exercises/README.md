# Session 03 — Exercise

## 🎯 Goal

Download assets from Gazebo Fuel, integrate them into a PX4 world, and run the simulation with the X500 drone.

---

## 📋 Tasks

### Task 1 — Download and place a model

Choose any model from [https://app.gazebosim.org/fuel/models](https://app.gazebosim.org/fuel/models) — pick something interesting to you (a building, vehicle, tree, obstacle).

```bash
# Download it
gz fuel download -u https://fuel.gazebosim.org/1.0/OWNER/models/NAME -v 4

# Copy to PX4 models directory (note the /1/ version folder)
cp -r ~/.gz/fuel/fuel.gazebosim.org/OWNER_lowercase/models/NAME/1 \
      /home/az/PX4-Autopilot/Tools/simulation/gz/models/NAME
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
- [ ] The three required plugins (Physics, UserCommands, SceneBroadcaster)
- [ ] A sun light and ground plane
- [ ] Your downloaded Fuel model via `<include><uri>model://NAME</uri></include>`
- [ ] The model placed at a position away from origin (so drone doesn't spawn inside it)

---

### Task 3 — Run with PX4

```bash
# Terminal 1
export GZ_SIM_RESOURCE_PATH=/home/az/PX4-Autopilot/Tools/simulation/gz/models
gz sim /home/az/PX4-Autopilot/Tools/simulation/gz/worlds/my_fuel_world.sdf

# Terminal 2
cd ~/PX4-Autopilot
PX4_GZ_STANDALONE=1 make px4_sitl gz_x500
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
gz fuel download -u https://fuel.gazebosim.org/1.0/OWNER/worlds/NAME -v 4

# Copy the SDF file to PX4
cp ~/.gz/fuel/fuel.gazebosim.org/OWNER_lowercase/worlds/NAME/1/*.sdf \
   /home/az/PX4-Autopilot/Tools/simulation/gz/worlds/my_downloaded_world.sdf

# Run it
export GZ_SIM_RESOURCE_PATH=/home/az/PX4-Autopilot/Tools/simulation/gz/models
gz sim /home/az/PX4-Autopilot/Tools/simulation/gz/worlds/my_downloaded_world.sdf
```

- [ ] Does the world load correctly?
- [ ] Are there any missing model errors? If yes, which models are missing?
- [ ] If the world is too heavy, open the SDF and remove some `<include>` blocks to lighten it

---

## 🔍 Self-Check Questions

1. What is the difference between using a Fuel URI directly in `<include>` vs downloading manually?
2. Why does the downloaded asset have a `/1/` subfolder, and what does it represent?
3. What does `GZ_SIM_RESOURCE_PATH` do, and what happens if it is not set?
4. A model shows as a grey box in Gazebo — what is the most likely cause?
5. You download a world from Fuel and it fails to load some models. How do you find out which models are missing?
6. What is the difference between `model://ModelName` and `https://fuel.gazebosim.org/...` as a URI?
