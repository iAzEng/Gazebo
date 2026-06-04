## 🎯 Learning Objectives

By the end of this session you will be able to:

- [ ] Understand what SITL means and how PX4 connects to Gazebo
- [ ] Launch the X500 drone in different PX4 built-in worlds
- [ ] Understand and use the `make px4_sitl gz_x500` command and its variants
- [ ] Use key environment variables to control the simulation
- [ ] Connect QGroundControl to the running simulation
- [ ] Inspect PX4-Gazebo topics from the terminal
- [ ] Run the simulation in standalone and headless modes

---

## 📚 Concepts Covered

### 1. What is SITL?

**SITL (Software In The Loop)** means running PX4 flight software on your computer instead of on real hardware. The flight controller (PX4) thinks it is flying a real drone, but all sensor data comes from Gazebo and all motor commands go back to Gazebo.

```
┌─────────────────────────────────────────────┐
│                Your Computer                │
│                                             │
│   ┌──────────┐   MAVLink    ┌────────────┐  │
│   │   PX4    │◄────────────►│  Gazebo    │  │
│   │  (SITL)  │   gz-bridge  │  Sim 8     │  │
│   └────┬─────┘              └────────────┘  │
│        │ MAVLink (UDP 14550)                │
│   ┌────▼─────┐                              │
│   │   QGC    │                              │
│   └──────────┘                              │
└─────────────────────────────────────────────┘
```

- **PX4 SITL** → runs the full autopilot stack on your PC
- **Gazebo** → simulates the physical world, drone physics, and sensors
- **gz-bridge** → connects PX4 and Gazebo (sends sensor data in, motor commands out)
- **QGroundControl** → connects via MAVLink on UDP port 14550, exactly like a real drone

### 2. The X500 Drone

The X500 is the default PX4 simulation drone — a quadrotor modeled after the real Holybro X500 kit. It is the standard starting point for all PX4 Gazebo simulations.

| Model | Command | Autostart ID |
|-------|---------|-------------|
| X500 (basic) | `make px4_sitl gz_x500` | 4001 |
| X500 + Depth Camera | `make px4_sitl gz_x500_depth` | 4002 |
| X500 + Vision Odometry | `make px4_sitl gz_x500_vision` | 4005 |
| X500 + Mono Camera | `make px4_sitl gz_x500_mono_cam` | 4010 |

We will use `gz_x500` (basic) throughout this session.

### 3. Built-in PX4 Worlds

PX4 ships with several ready-made worlds. The command format to run a specific world is:

```bash
make px4_sitl gz_x500_WORLDNAME
```

| World | Command | Description |
|-------|---------|-------------|
| default | `make px4_sitl gz_x500` | Flat ground, minimal — best for testing |
| baylands | `make px4_sitl gz_x500_baylands` | Outdoor environment near water, rich 3D scenery |
| windy | `make px4_sitl gz_x500_windy` | Empty world with wind forces enabled |
| walls | `make px4_sitl gz_x500_walls` | Empty world with walls for collision avoidance testing |
| aruco | `make px4_sitl gz_x500_aruco` | World with ArUco marker for precision landing |
| moving platform | `make px4_sitl gz_x500_moving_platform` | A flat moving platform (simulates ship/truck) |

> ⚠️ **Baylands note:** You may see warnings about mesh collisions when loading Baylands. This is expected and can be ignored — it does not break the simulation.

> ⚠️ **Do NOT use `_default` suffix:** Use `make px4_sitl gz_x500` not `make px4_sitl gz_x500_default` — the latter will fail.

### 4. Environment Variables

Environment variables let you customize the simulation without changing any code.

```bash
# Set the world
PX4_GZ_WORLD=baylands make px4_sitl gz_x500

# Set spawn position (x, y, z, roll, pitch, yaw)
PX4_GZ_MODEL_POSE="0,0,0.1,0,0,0" make px4_sitl gz_x500

# Set home GPS location
PX4_HOME_LAT=24.7136 PX4_HOME_LON=46.6753 PX4_HOME_ALT=612 make px4_sitl gz_x500

# Run faster than real time (2x speed)
PX4_SIM_SPEED_FACTOR=2 make px4_sitl gz_x500

# Run without the Gazebo GUI (faster, less RAM)
HEADLESS=1 make px4_sitl gz_x500
```

| Variable | Purpose |
|----------|---------|
| `PX4_GZ_WORLD` | Which world to load |
| `PX4_GZ_MODEL_POSE` | Where to spawn the drone (x,y,z,r,p,y) |
| `PX4_HOME_LAT/LON/ALT` | GPS home location |
| `PX4_SIM_SPEED_FACTOR` | Simulation speed multiplier |
| `HEADLESS=1` | Run without Gazebo GUI |
| `PX4_GZ_STANDALONE=1` | Start PX4 and Gazebo separately |

### 5. Standalone Mode

By default, one `make` command starts both PX4 and Gazebo together. In **standalone mode**, you start them separately — useful when you want to keep Gazebo running while restarting PX4.

**One-time setup — create `~/.simulation-gazebo/`**

The `simulation-gazebo` Python script downloads PX4's Gazebo models and worlds into `~/.simulation-gazebo/` and sets up the `server.config` file that loads all required sensor plugins. Run this once:

```bash
wget https://raw.githubusercontent.com/PX4/PX4-gazebo-models/main/simulation-gazebo
python3 ~/simulation-gazebo --world default
```

This creates `~/.simulation-gazebo/` containing:
```
~/.simulation-gazebo/
├── models/          ← PX4 drone and sensor models
├── worlds/          ← default, baylands, windy, walls, ... world files
└── server.config    ← loads sensor plugins (IMU, GPS, barometer, magnetometer)
```

**Terminal 1 — Start Gazebo only:**
```bash
python3 ~/simulation-gazebo --world default
```

**Terminal 2 — Start PX4 and connect to running Gazebo:**
```bash
cd ~/PX4-Autopilot
PX4_GZ_STANDALONE=1 PX4_GZ_WORLD=default make px4_sitl gz_x500
```

### 6. QGroundControl Connection

QGroundControl connects automatically when PX4 SITL is running. No configuration needed.

- Open QGroundControl **after** starting the simulation
- It listens on UDP port `14550` by default
- You will see the drone appear on the map with GPS lock
- You can arm, change flight modes, and plan missions exactly like a real drone

**If QGC does not connect automatically:**
```
QGC → Application Settings → Comm Links → Add → UDP → Port 14550
```

### 7. Inspecting PX4-Gazebo Topics

When PX4 + Gazebo are running, you can inspect all active topics the same way as in Session 1:

```bash
# See all topics (PX4 topics appear alongside Gazebo topics)
gz topic -l

# Watch the drone's IMU data
gz topic -e -t /world/default/model/x500_0/link/base_link/sensor/imu_sensor/imu

# Watch clock
gz topic -e -t /clock

# Watch pose of the drone
gz model -m x500_0 --pose
```

---

## 📂 Files in This Session

```
gaz/
├── README.md                          ← This file
├── scripts/
│   └── run_worlds.sh                  ← Helper to quickly switch between worlds
└── exercises/
    └── README.md                      ← Exercise instructions
```

No SDF files this session — we are using PX4's built-in worlds.

---

## 🛠️ Guided Walkthrough

### Step 1 — Build PX4 first

Before running any simulation, PX4 must be built:

```bash
cd ~/PX4-Autopilot
make px4_sitl gz_x500
```

The first build takes several minutes. Subsequent runs are fast.

### Step 2 — Run the default world

```bash
cd ~/PX4-Autopilot
make px4_sitl gz_x500
```

You will see:
- Gazebo launches with the drone on a flat grey ground
- PX4 terminal prints boot messages and stabilizes
- Open QGroundControl → drone appears on map

**In a second terminal, inspect what's running:**
```bash
gz topic -l
gz model --list
gz model -m x500_0 --pose
```

### Step 3 — Arm and fly with QGroundControl

In QGroundControl:
1. Wait for the drone status to show **Ready to Fly**
2. Click **Takeoff** → set altitude → **Slide to confirm**
3. Watch the drone lift off in Gazebo
4. Click **Land** to bring it back down

### Step 4 — Run the Baylands world

Open a new terminal (close the previous simulation first):

```bash
cd ~/PX4-Autopilot
make px4_sitl gz_x500_baylands
```

Observe the difference:
- Rich outdoor environment with trees, water, terrain
- Same drone, same QGC connection, same topics
- May load slower due to mesh complexity
- You may see mesh warnings in the terminal — ignore them

```bash
gz model -m x500_0 --pose    # same command, different world
gz topic -l                  # same topics structure
```

### Step 5 — Run the windy world

```bash
cd ~/PX4-Autopilot
make px4_sitl gz_x500_windy
```

- Arm and hover the drone
- Observe the drone fighting wind disturbances in Gazebo
- Watch attitude changes in QGroundControl's HUD

### Step 6 — Try environment variables

```bash
cd ~/PX4-Autopilot

# Run at 2x speed
PX4_SIM_SPEED_FACTOR=2 make px4_sitl gz_x500

# Spawn drone at a different position
PX4_GZ_MODEL_POSE="5,5,0.1,0,0,0" make px4_sitl gz_x500

# Run headless (no GUI) — PX4 only, no Gazebo window
HEADLESS=1 make px4_sitl gz_x500
```

### Step 7 — Run the inspect script

```bash
# While a simulation is running:
bash scripts/run_worlds.sh
```

---

## ✏️ Exercise

> Full instructions are in [`exercises/README.md`](./exercises/README.md)

---

## ❓ Common Issues & Debugging

**`ninja: error: unknown target 'gz_x500' (note that "make distclean" will remove all files in gz folder including models and worlds)`**
```bash
make distclean
git submodule update --init --recursive
make px4_sitl gz_x500
```

**Gazebo opens but drone never appears:**
- Wait 30–60 seconds on first run — models download from Gazebo Fuel
- Check internet connection

**QGroundControl does not connect:**
- Make sure QGC is opened **after** the simulation starts
- Check that PX4 terminal shows `[mavlink] mode: Normal` — this means MAVLink is active

**Baylands throws warnings:**
- Expected behavior — ignore the mesh collision warnings
- The simulation still works correctly

**Simulation is very slow:**
- Baylands is heavy — try the default world first
- Close other applications
- Use `HEADLESS=1` to remove the Gazebo GUI load

**`ERROR [gz_bridge] Service call timed out`:**
- Gazebo hasn't fully started yet — wait a few seconds and try again
- If persistent, run `make distclean` and rebuild

---

## 🔗 References

- [PX4 Gazebo Simulation Docs](https://docs.px4.io/main/en/sim_gazebo_gz/)
- [PX4 Gazebo Worlds](https://docs.px4.io/main/en/sim_gazebo_gz/worlds)
- [PX4 Gazebo Vehicles](https://docs.px4.io/main/en/sim_gazebo_gz/vehicles.html)
- [PX4 Gazebo Models Repository](https://docs.px4.io/main/en/sim_gazebo_gz/gazebo_models.html)
- [QGroundControl Docs](https://docs.qgroundcontrol.com/master/en/)
