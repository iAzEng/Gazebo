#!/bin/bash
# ============================================================
# run_worlds.sh
# Quick reference and inspection helper for Session 02
#
# USAGE:
#   1. Start a simulation in one terminal
#   2. Run this script in another terminal:
#        bash scripts/run_worlds.sh
# ============================================================

echo ""
echo "============================================================"
echo "  PX4 + Gazebo World Inspector — Session 02"
echo "============================================================"
echo ""

# ── Check if gz is running ───────────────────────────────────
echo ">>> Checking for running simulation..."
TOPICS=$(gz topic -l 2>/dev/null)
if [ -z "$TOPICS" ]; then
    echo ""
    echo "[WARNING] No simulation detected."
    echo "          Start a world first, then press Play."
    echo ""
    exit 1
fi
echo "    Simulation detected!"
echo ""

# ── List all models ──────────────────────────────────────────
echo ">>> Models in simulation:"
echo "------------------------------------------------------------"
gz model --list 2>/dev/null
echo ""

# ── Drone pose ───────────────────────────────────────────────
echo ">>> X500 drone pose:"
echo "------------------------------------------------------------"
gz model -m x500_0 --pose 2>/dev/null || echo "    (x500_0 not found — is the simulation running?)"
echo ""

# ── Active topic count ───────────────────────────────────────
echo ">>> Active topics:"
echo "------------------------------------------------------------"
gz topic -l 2>/dev/null
echo ""

# ── Quick reference ──────────────────────────────────────────
echo "============================================================"
echo "  WORLD LAUNCH COMMANDS:"
echo ""
echo "  Default:         make px4_sitl gz_x500"
echo "  Baylands:        make px4_sitl gz_x500_baylands"
echo "  Windy:           make px4_sitl gz_x500_windy"
echo "  Walls:           make px4_sitl gz_x500_walls"
echo "  ArUco:           make px4_sitl gz_x500_aruco"
echo "  Moving platform: make px4_sitl gz_x500_moving_platform"
echo ""
echo "  ENVIRONMENT VARIABLES:"
echo ""
echo "  PX4_GZ_WORLD=baylands make px4_sitl gz_x500"
echo "  PX4_GZ_MODEL_POSE=\"5,5,0.1,0,0,0\" make px4_sitl gz_x500"
echo "  PX4_SIM_SPEED_FACTOR=2 make px4_sitl gz_x500"
echo "  HEADLESS=1 make px4_sitl gz_x500"
echo "  PX4_GZ_STANDALONE=1 make px4_sitl gz_x500"
echo "============================================================"
echo ""
