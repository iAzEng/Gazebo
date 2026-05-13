# Session 02 — Exercise

## 🎯 Goal

Get comfortable launching and observing PX4 + Gazebo simulations across different worlds, and understand what changes and what stays the same between them.

---

## 📋 Tasks

### Task 1 — Run 3 different worlds

Run each of the following worlds, arm the drone, and hover briefly:

| World | Command |
|-------|---------|
| Default | `make px4_sitl gz_x500` |
| Baylands | `make px4_sitl gz_x500_baylands` |
| Windy | `make px4_sitl gz_x500_windy` |

For each world, answer in a comment or note:
- [ ] What does the environment look like?
- [ ] Does QGroundControl connect automatically?
- [ ] Are the gz topics the same across all three worlds?

---

### Task 2 — Use environment variables

Run the default world with each of these modifications separately:

```bash
# 1. Spawn the drone at position X=10, Y=5
PX4_GZ_MODEL_POSE="10,5,0.1,0,0,0" make px4_sitl gz_x500

# 2. Run at 2x speed
PX4_SIM_SPEED_FACTOR=2 make px4_sitl gz_x500

# 3. Run headless (no Gazebo window)
HEADLESS=1 make px4_sitl gz_x500
```

- [ ] In task 1, does the drone spawn at the correct position in Gazebo?
- [ ] In task 2, does the sim time in QGC run faster than real time?
- [ ] In task 3, can you still connect QGC even without the Gazebo window?

---

### Task 3 — Inspect topics

While the default world is running with the drone armed and hovering:

```bash
# Run these commands in a separate terminal
gz topic -l
gz model -m x500_0 --pose
gz topic -e -t /clock
```

- [ ] How many topics are active?
- [ ] What is the drone's pose when it is on the ground vs hovering?
- [ ] What does the `/clock` topic show?

---

### Task 4 — Standalone mode

Start Gazebo and PX4 separately:

**Terminal 1:**
```bash
cd ~/.simulation-gazebo
python3 simulation-gazebo --world default
```

**Terminal 2:**
```bash
cd ~/PX4-Autopilot
PX4_GZ_STANDALONE=1 make px4_sitl gz_x500
```

- [ ] Does the drone appear in the already-running Gazebo instance?
- [ ] Does QGC connect the same way?
- [ ] Try closing Terminal 2 and restarting PX4 without closing Gazebo — does it work?

---

## 🔍 Self-Check Questions

1. What is SITL and why is it useful for drone development?
2. What does the `gz-bridge` do between PX4 and Gazebo?
3. What port does QGroundControl use to connect to PX4 SITL?
4. What is the difference between `make px4_sitl gz_x500` and `make px4_sitl gz_x500_baylands`?
5. What does `HEADLESS=1` do and when would you use it?
6. What does `PX4_GZ_STANDALONE=1` enable and why is it useful?
7. Why should you NOT use `make px4_sitl gz_x500_default`?
