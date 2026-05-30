# SDF Quick Reference — Gazebo Sim 8

A one-page reference for the most common SDF tags used in Session 01 and beyond.

---

## World Skeleton

```xml
<?xml version="1.0" ?>
<sdf version="1.10">
  <world name="YOUR_WORLD_NAME">

    <physics name="1ms" type="ignored">
      <max_step_size>0.001</max_step_size>
      <real_time_factor>1.0</real_time_factor>
    </physics>

    <plugin filename="gz-sim-physics-system"
            name="gz::sim::systems::Physics"/>
    <plugin filename="gz-sim-user-commands-system"
            name="gz::sim::systems::UserCommands"/>
    <plugin filename="gz-sim-scene-broadcaster-system"
            name="gz::sim::systems::SceneBroadcaster"/>

    <!-- lights, models go here -->

  </world>
</sdf>
```

---

## Pose

```xml
<pose>X Y Z Roll Pitch Yaw</pose>
```

| Value | Unit | Notes |
|-------|------|-------|
| X, Y, Z | meters | position |
| Roll, Pitch, Yaw | radians | rotation |

**Common angles:**

| Degrees | Radians |
|---------|---------|
| 0° | 0 |
| 45° | 0.7854 |
| 90° | 1.5708 |
| 180° | 3.1416 |

---

## Z Position for Objects on Ground

```
Box      (height H):    Z = H / 2
Cylinder (length L):    Z = L / 2
Sphere   (radius R):    Z = R
```

---

## Geometry Shapes

```xml
<!-- Box -->
<geometry>
  <box><size>WIDTH DEPTH HEIGHT</size></box>
</geometry>

<!-- Cylinder -->
<geometry>
  <cylinder>
    <radius>R</radius>
    <length>L</length>   <!-- = height when upright -->
  </cylinder>
</geometry>

<!-- Sphere -->
<geometry>
  <sphere><radius>R</radius></sphere>
</geometry>

<!-- Plane (infinite, for ground) -->
<geometry>
  <plane>
    <normal>0 0 1</normal>  <!-- up = Z axis -->
    <size>100 100</size>    <!-- visual size only -->
  </plane>
</geometry>
```

---

## Colors (Material)

```xml
<material>
  <ambient>R G B A</ambient>    <!-- color in shadow -->
  <diffuse>R G B A</diffuse>    <!-- main lit color -->
  <specular>R G B A</specular>  <!-- highlight/shine -->
</material>
```

Values: 0.0 to 1.0  |  Alpha: 1=opaque, 0=transparent

**Common colors:**

| Color | R G B |
|-------|-------|
| Red | 1.0 0.0 0.0 |
| Green | 0.0 1.0 0.0 |
| Blue | 0.0 0.0 1.0 |
| Yellow | 1.0 1.0 0.0 |
| Orange | 1.0 0.5 0.0 |
| Purple | 0.5 0.0 1.0 |
| White | 1.0 1.0 1.0 |
| Black | 0.0 0.0 0.0 |
| Grey | 0.5 0.5 0.5 |

---

## Static vs Dynamic

| | Static | Dynamic |
|---|---|---|
| `<static>` tag | `<static>true</static>` | omit or `false` |
| Gravity applies? | ❌ No | ✅ Yes |
| Needs `<inertial>`? | ❌ No | ✅ Yes |
| Use for | ground, walls, buildings | robots, balls, objects that move |

---

## Inertia Formulas

**Solid sphere** (mass m, radius r):
```
Ixx = Iyy = Izz = (2/5) * m * r²
Off-diagonal (ixy, ixz, iyz) = 0
```

**Solid box** (mass m, sides x, y, z):
```
Ixx = (1/12) * m * (y² + z²)
Iyy = (1/12) * m * (x² + z²)
Izz = (1/12) * m * (x² + y²)
```

**Solid cylinder** (mass m, radius r, height h):
```
Ixx = Iyy = (1/12) * m * (3r² + h²)
Izz = (1/2) * m * r²
```

---

## Light Types

```xml
<!-- Directional (like sun — parallel rays) -->
<light type="directional" name="sun">
  <direction>-0.5 0.1 -0.9</direction>
  ...
</light>

<!-- Point (like a bulb — all directions) -->
<light type="point" name="lamp">
  <pose>0 0 3 0 0 0</pose>
  ...
</light>

<!-- Spot (like a flashlight — cone) -->
<light type="spot" name="torch">
  <pose>0 0 5 0 1.5708 0</pose>
  <spot>
    <inner_angle>0.5</inner_angle>
    <outer_angle>1.0</outer_angle>
    <falloff>1.0</falloff>
  </spot>
  ...
</light>
```

---

## gz CLI Commands

```bash
# Run a world
gz sim MY_WORLD.sdf

# Validate an SDF file (check for errors before running)
gz sdf -k MY_WORLD.sdf

# List all active topics
gz topic -l

# Echo messages on a topic
gz topic -e -t /TOPIC_NAME

# List all models in running sim
gz model --list

# Get pose of a model
gz model -m MODEL_NAME --pose

# Get full info about a model
gz model -m MODEL_NAME --info
```

---

## Include an External Model

**From Gazebo Fuel (online):**
```xml
<include>
  <uri>https://fuel.gazebosim.org/1.0/OpenRobotics/models/Coke</uri>
  <name>my_coke_can</name>
  <pose>2 0 0 0 0 0</pose>
</include>
```

**From a local folder:**

The folder name must match the model name used in `model://`.
`GZ_SIM_RESOURCE_PATH` must point to the folder that **contains** the model folder.

Required structure:
```
my_models/              ← set GZ_SIM_RESOURCE_PATH to this
└── simple_box/         ← folder name = model:// name
    ├── model.config    ← required metadata file
    └── model.sdf       ← model definition
```

```bash
export GZ_SIM_RESOURCE_PATH=/path/to/my_models
gz sim my_world.sdf
```

```xml
<include>
  <uri>model://simple_box</uri>
  <name>box1</name>
  <pose>0 0 0.5 0 0 0</pose>
</include>
```

> See `models/simple_box/` in this session for a working example.

---

*Gazebo Sim 8 (Harmonic) — SDFormat 1.10 — Drone Simulation Bootcamp*
