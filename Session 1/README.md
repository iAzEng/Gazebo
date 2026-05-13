## 🎯 Learning Objectives

By the end of this session you will be able to:

- [ ] Launch Gazebo and navigate the GUI confidently
- [ ] Use `gz` CLI tools to inspect a running simulation
- [ ] Explain the structure of an SDF file and the role of each tag
- [ ] Build a simple world from scratch with a ground plane, light, and a static object
- [ ] Understand how joints connect links together
- [ ] Load an external model from Gazebo Fuel using `<include>`
- [ ] Run your world in Gazebo and verify it works

---

## 📚 Concepts Covered

### 1. What is Gazebo Sim 8?

Gazebo Sim 8 (codename **Harmonic**) is an open-source robotics simulator. It is the modern successor to Gazebo Classic and is the standard simulator used with PX4 for drone simulation.

Key things to know:
- Everything in simulation is an **Entity** (models, links, sensors, lights — everything)
- The world is described in **SDF (Simulation Description Format)** — an XML-based file
- Gazebo is **plugin-based** — almost every feature (physics, rendering, sensors) is a plugin
- Communication between components uses **gz-transport** (a topic/message system similar to ROS)

### 2. Gazebo vs Gazebo Classic

| | Gazebo Classic | Gazebo Sim 8 (Harmonic) |
|---|---|---|
| Also known as | Gazebo 11 | Gazebo Ignition / New Gazebo |
| Command | `gazebo` | `gz sim` |
| Config format | URDF / SDF | SDF only |
| PX4 support | Legacy | ✅ Current standard |
| Ubuntu 22.04 | Not recommended | ✅ Default |

### 3. The SDF File Structure

Every world file follows this hierarchy:

```
<sdf>
  <world>
    ├── <physics>         — simulation engine settings
    ├── <plugin>          — system-level plugins (Physics, SceneBroadcaster...)
    ├── <gui>             — GUI layout and GUI plugins
    ├── <light>           — light sources (sun, directional, spot)
    └── <model>           — objects in the world
          ├── <pose>      — position and orientation
          ├── <static>    — does physics apply to this model?
          └── <link>      — a rigid body part of the model
                ├── <inertial>   — mass and inertia matrix
                ├── <visual>     — what it looks like
                └── <collision>  — how physics interacts with it
          └── <joint>     — connection between two links
```

### 4. SDF Tags Explained

| Tag | Purpose |
|-----|---------|
| `<sdf version="1.10">` | SDF format version |
| `<world name="...">` | Container for everything |
| `<physics>` | Step size, real-time factor |
| `<plugin filename="..." name="...">` | Load a shared library into simulation |
| `<model name="...">` | A group of links + joints |
| `<static>true</static>` | Object won't move (no physics needed) |
| `<pose>X Y Z R P Y</pose>` | Position (meters) + Rotation (radians) |
| `<link name="...">` | A single rigid body |
| `<visual>` | Rendered appearance |
| `<collision>` | Physics collision shape |
| `<geometry>` | Shape: box, cylinder, sphere, mesh |
| `<material>` | Color: ambient, diffuse, specular |
| `<inertial>` | Mass and moment of inertia |
| `<joint>` | Connection between two links |
| `<light>` | Light source in the world |
| `<include>` | Load an external model into the world |

### 5. Essential Plugins for Every World

These three plugins are required in almost every world:

```xml
<!-- Simulates physics (gravity, collisions, forces) -->
<plugin filename="gz-sim-physics-system"
        name="gz::sim::systems::Physics"/>

<!-- Allows you to interact with the world via GUI/CLI -->
<plugin filename="gz-sim-user-commands-system"
        name="gz::sim::systems::UserCommands"/>

<!-- Broadcasts the scene so the GUI can render it -->
<plugin filename="gz-sim-scene-broadcaster-system"
        name="gz::sim::systems::SceneBroadcaster"/>
```

Without these, your world either won't simulate physics, won't render, or won't respond to commands.

### 6. Joints

A joint connects two links inside a model. It defines how they move relative to each other.

```xml
<joint name="my_joint" type="revolute">
  <parent>base_link</parent>
  <child>arm_link</child>
  <axis>
    <xyz expressed_in="__model__">0 0 1</xyz>  <!-- rotation axis -->
    <limit>
      <lower>-3.1416</lower>
      <upper>3.1416</upper>
    </limit>
  </axis>
</joint>
```

**Joint types:**

| Type | Movement |
|------|----------|
| `revolute` | Rotates around 1 axis (hinge) |
| `prismatic` | Slides along 1 axis (piston) |
| `fixed` | No movement, rigid connection |
| `ball` | 3 rotational degrees of freedom |

When you open a PX4 drone SDF you will see revolute joints connecting each rotor to the body — now you know what they mean.

### 7. Including External Models (Gazebo Fuel)

Instead of building every object from scratch, you can pull ready-made models from [Gazebo Fuel](https://app.gazebosim.org/fuel):

```xml
<include>
  <uri>https://fuel.gazebosim.org/1.0/OpenRobotics/models/Coke</uri>
  <name>coke_can</name>
  <pose>-3 0 0 0 0 0</pose>
</include>
```

The model downloads on first run and is cached locally. Multiple instances of the same model must each have a different `<name>`.

### 8. The gz CLI — Your Debugging Tool

The `gz` command-line tool is essential for inspecting and interacting with a running simulation.

```bash
# List ALL active topics in a running simulation
gz topic -l

# Echo (print) all messages published on a topic
gz topic -e -t /topic_name

# Publish a message to a topic
gz topic -t "/topic_name" -m gz.msgs.MessageType -p "field: value"

# List all models currently in the simulation
gz model --list

# Get info about a specific model
gz model -m model_name --info

# Get the pose (position) of a model
gz model -m model_name --pose
```

---

## 📂 Files in This Session

```
gaz/
├── README.md                          ← This file
├── SDF_CHEATSHEET.md
├── my_first_world.sdf                 ← Reference solution
├── worlds/
│   ├── 01_empty_world.sdf             ← Bare minimum world
│   ├── 02_world_with_light.sdf        ← Sun + ground plane
│   ├── 03_world_with_objects.sdf      ← Shapes, colors, dynamic object
│   └── 04_joints_and_include.sdf      ← Joints + Fuel model import
├── models/
│   └── model.sdf                      ← Standalone reusable model
├── scripts/
│   └── inspect_world.sh
└── exercises/
    └── README.md
```

---

## 🛠️ Guided Walkthrough

### Step 1 — Launch your first world

```bash
gz sim worlds/01_empty_world.sdf
```

Press ▶️ Play. Explore the GUI: entity tree, component inspector, toolbar.

### Step 2 — Inspect it with the CLI

```bash
gz topic -l
gz topic -e -t /world/empty_world/stats
```

### Step 3 — Add a light and ground

```bash
gz sim worlds/02_world_with_light.sdf
```

Find the `<light>` tag and the `sun_visual` model. Understand why both are needed.

### Step 4 — Explore objects

```bash
gz sim worlds/03_world_with_objects.sdf
gz model --list
gz model -m red_box --pose
```

For each visible object, find its `<model>` tag in the SDF and match the properties.

### Step 5 — Joints and external models

```bash
gz sim worlds/04_joints_and_include.sdf
gz model --list
gz model -m simple_arm --info
```

Observe the `simple_arm` model — find the two links and the joint in the SDF. Then find the Coke can loaded via `<include>`.

### Step 6 — Run the inspect script

```bash
bash scripts/inspect_world.sh
```

---

## ✏️ Exercise

> Full instructions are in [`exercises/README.md`](./exercises/README.md)

**Goal:** Build `my_first_world.sdf` from scratch.

---

## ❓ Common Issues & Debugging

**World launches but is completely black / nothing renders:**
- Check that `gz-sim-scene-broadcaster-system` plugin is present

**Objects fall through the ground:**
- Make sure the ground plane has a `<collision>` tag
- Check that `gz-sim-physics-system` is loaded

**`gz topic -l` shows nothing:**
- The simulation must be running (press play), not paused

**Model spawns underground:**
- Check your Z value — it must account for the shape's size

**SDF file won't load — parse error:**
- Use `gz sdf -k your_file.sdf` to validate before running

**Fuel model doesn't load:**
- Check your internet connection on first run
- The model is cached after the first download

---

## 🔗 References

- [SDFormat Specification](http://sdformat.org/spec)
- [Gazebo Harmonic: Building a Robot](https://gazebosim.org/docs/harmonic/building_robot/)
- [Gazebo Harmonic: SDF Worlds](https://gazebosim.org/docs/harmonic/sdf_worlds/)
- [Gazebo Fuel](https://app.gazebosim.org/fuel)
- [gz CLI documentation](https://gazebosim.org/api/transport/13/)
