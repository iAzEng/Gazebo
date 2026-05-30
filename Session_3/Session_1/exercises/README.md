# Session 01 — Exercise

## 🎯 Goal

Build your own Gazebo world from scratch called `my_first_world.sdf`.

---

## 📋 Requirements

### 1. World Setup
- [ ] Correct SDF version declaration
- [ ] A world with a unique name
- [ ] The three required system plugins (Physics, UserCommands, SceneBroadcaster)
- [ ] A `<physics>` block with step size and real-time factor

### 2. Environment
- [ ] A directional light (sun)
- [ ] A ground plane with both `<visual>` and `<collision>`

### 3. Objects — minimum 4 objects using at least 3 different shapes

Each object must:
- [ ] Have a **unique name**
- [ ] Have a **different color**
- [ ] Be placed at a **different position**
- [ ] Have both `<visual>` and `<collision>`

### 4. At least 1 dynamic object
- [ ] No `<static>true</static>` tag
- [ ] Has `<inertial>` with `<mass>` and `<inertia>`
- [ ] Placed above the ground so it falls when play is pressed

### 5. At least 1 joint
- [ ] A model with **two links** connected by a **revolute** or **fixed** joint
- [ ] `<parent>` and `<child>` correctly defined
- [ ] Joint has an `<axis>` with `<xyz>` and `<limit>`

### 6. At least 1 included model
- [ ] Use `<include>` to load any model from [Gazebo Fuel](https://app.gazebosim.org/fuel)
- [ ] Give it a unique `<name>` and a `<pose>`

---

## 💡 Hints

**Pose:**
```
<pose>X Y Z Roll Pitch Yaw</pose>
— X, Y, Z in meters | Roll, Pitch, Yaw in radians
— 90° = 1.5708 rad
```

**Z on ground:**
```
Box (height H) → Z = H/2
Cylinder (length L) → Z = L/2
Sphere (radius R) → Z = R
```

**Inertia for a solid sphere** (mass m, radius r):
```
Ixx = Iyy = Izz = (2/5) * m * r^2
```

**Inertia for a solid box** (mass m, sides x, y, z):
```
Ixx = (1/12) * m * (y^2 + z^2)
Iyy = (1/12) * m * (x^2 + z^2)
Izz = (1/12) * m * (x^2 + y^2)
```

**Basic joint structure:**
```xml
<joint name="my_joint" type="revolute">
  <parent>link_one</parent>
  <child>link_two</child>
  <axis>
    <xyz expressed_in="__model__">0 0 1</xyz>
    <limit>
      <lower>-3.1416</lower>
      <upper>3.1416</upper>
    </limit>
  </axis>
</joint>
```

**Fuel include:**
```xml
<include>
  <uri>https://fuel.gazebosim.org/1.0/OpenRobotics/models/Coke</uri>
  <name>my_coke</name>
  <pose>2 0 0 0 0 0</pose>
</include>
```

**Validate before running:**
```bash
gz sdf -k my_first_world.sdf
```

---

## ✅ How to Test

```bash
gz sdf -k my_first_world.sdf      # validate
gz sim my_first_world.sdf         # run — then press Play ▶️
gz model --list                   # check all models appear
gz model -m YOUR_ARM_NAME --info  # check joint info
gz topic -l | grep stats          # check world is running
```

---

## 🔍 Self-Check Questions

1. What happens if you remove the `gz-sim-physics-system` plugin?
2. What happens if you remove the `<collision>` tag from the ground plane?
3. Why does a dynamic object need `<inertial>` but a static one doesn't?
4. If a box has height=2.0, what Z value places it flat on the ground?
5. What is the difference between `<ambient>` and `<diffuse>`?
6. What is the difference between a `revolute` and a `fixed` joint?
7. What happens if two `<include>` blocks use the same `<name>`?
