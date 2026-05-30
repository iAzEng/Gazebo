#!/bin/bash
# ============================================================
# inspect_world.sh
# Helper script to inspect a running Gazebo Sim 8 world
#
# USAGE:
#   1. Launch a world in one terminal:
#        gz sim worlds/03_world_with_objects.sdf
#      Then press Play
#
#   2. Run this script in another terminal:
#        bash scripts/inspect_world.sh
#
# ============================================================

echo ""
echo "============================================================"
echo "  Gazebo World Inspector — Session 01"
echo "============================================================"
echo ""

# ── Check if gz is available ────────────────────────────────
if ! command -v gz &> /dev/null; then
    echo "[ERROR] 'gz' command not found."
    echo "        Make sure Gazebo Sim 8 is installed and sourced."
    echo "        Try: source /usr/share/gz/gz-sim8/setup.sh"
    exit 1
fi

# ── Check if a simulation is running ────────────────────────
echo ">>> Checking for running Gazebo simulation..."
TOPICS=$(gz topic -l 2>/dev/null)
if [ -z "$TOPICS" ]; then
    echo ""
    echo "[WARNING] No active topics found."
    echo "          Is a Gazebo world running? Is it PLAYING (not paused)?"
    echo "          Start a world and press the Play button first."
    echo ""
    exit 1
fi
echo "    Simulation detected!"
echo ""

# ── List all active topics ───────────────────────────────────
echo ">>> All active topics in the simulation:"
echo "------------------------------------------------------------"
gz topic -l
echo ""

# ── List all models ──────────────────────────────────────────
echo ">>> Models currently in the simulation:"
echo "------------------------------------------------------------"
gz model --list 2>/dev/null || echo "    (could not retrieve model list)"
echo ""

# ── World stats ──────────────────────────────────────────────
echo ">>> World statistics (1 message, then stopping):"
echo "------------------------------------------------------------"
timeout 3 gz topic -e -t /world/world_with_objects/stats 2>/dev/null \
    || echo "    (topic not found — check your world name)"
echo ""

# ── Tip ──────────────────────────────────────────────────────
echo "============================================================"
echo "  USEFUL COMMANDS TO TRY:"
echo ""
echo "  gz topic -l                         # list all topics"
echo "  gz topic -e -t /TOPIC_NAME          # echo a topic"
echo "  gz model --list                     # list all models"
echo "  gz model -m MODEL_NAME --pose       # get model pose"
echo "  gz model -m MODEL_NAME --info       # get model info"
echo "  gz sdf -k FILE.sdf                  # validate SDF file"
echo "============================================================"
echo ""
