#!/usr/bin/env python3
"""
convert_to_glb.py — Session 04 helper
Converts .obj or .dae to .glb with textures embedded.

Sketchfab downloads often separate the mesh and textures into different folders:
    download-folder/
    ├── source/
    │   └── model.obj   ← mesh (usually missing .mtl)
    └── textures/       ← textures here, NOT alongside the mesh
        └── *.png/.jpg

This script asks for the root download folder, finds the textures/ subfolder,
copies textures alongside the mesh, auto-creates a .mtl if missing, converts
to GLB, then cleans up.

Usage (interactive):
    python3 convert_to_glb.py INPUT_FILE [OUTPUT_FILE]

Usage (non-interactive, from import_asset.sh):
    python3 convert_to_glb.py INPUT_FILE OUTPUT_FILE --base-dir /path/to/root
"""

import sys
import os
import shutil
import argparse

IMAGE_EXTS = ('.png', '.jpg', '.jpeg', '.tga', '.bmp', '.tif', '.tiff')


def find_textures_dir(base_dir, obj_dir):
    """
    Search for a textures/ folder in order of priority:
    1. base_dir/textures/      (Sketchfab structure: root/textures/)
    2. obj_dir/../textures/    (mesh in source/, textures in ../textures/)
    3. obj_dir/textures/       (textures alongside the mesh)
    """
    candidates = [
        os.path.join(base_dir, 'textures'),
        os.path.join(base_dir, 'Textures'),
        os.path.join(obj_dir, '..', 'textures'),
        os.path.join(obj_dir, '..', 'Textures'),
        os.path.join(obj_dir, 'textures'),
        os.path.join(obj_dir, 'Textures'),
    ]
    for c in candidates:
        real = os.path.realpath(c)
        if os.path.isdir(real):
            return real
    return None


def list_texture_files(tex_dir):
    return [f for f in os.listdir(tex_dir)
            if os.path.splitext(f)[1].lower() in IMAGE_EXTS]


def match_texture(material_name, tex_files):
    """
    Match a material name to a texture file.
    Sketchfab pattern: sea_MaterialName_color.tga.png
    The material name usually appears as a substring of the texture filename.
    """
    mat_lower = material_name.lower()
    color_keywords = ('color', 'basecolor', 'albedo', 'diffuse', '_col')

    # Priority 1: texture contains material name AND a color keyword
    for tex in tex_files:
        t = tex.lower()
        if mat_lower in t and any(k in t for k in color_keywords):
            return tex

    # Priority 2: texture contains material name (any match)
    for tex in tex_files:
        if mat_lower in tex.lower():
            return tex

    # Priority 3: texture named "default" for material named "default"
    if 'default' in mat_lower:
        for tex in tex_files:
            if 'default' in tex.lower():
                return tex

    return None


def parse_obj_materials(obj_path):
    """Read all unique 'usemtl' material names from an OBJ file."""
    materials = []
    with open(obj_path, 'r', errors='replace') as f:
        for line in f:
            if line.startswith('usemtl '):
                mat = line.strip().split(None, 1)[1]
                if mat not in materials:
                    materials.append(mat)
    return materials


def build_mtl(obj_path, tex_dir, tex_files):
    """
    Create a .mtl file alongside the OBJ with correct texture paths.
    Uses only filenames (textures will be copied to the same dir as the OBJ).
    Returns path to the created MTL.
    """
    materials = parse_obj_materials(obj_path)
    if not materials:
        print("  [WARNING] No 'usemtl' statements in OBJ — cannot build MTL.")
        return None

    mtl_path = os.path.splitext(obj_path)[0] + '.mtl'
    print(f"  Building MTL: {mtl_path}")

    unmapped = []
    with open(mtl_path, 'w') as f:
        for mat in materials:
            tex = match_texture(mat, tex_files)
            f.write(f'\nnewmtl {mat}\n')
            f.write('Ka 1 1 1\nKd 1 1 1\nd 1\nNs 0\nillum 1\n')
            if tex:
                # Use only filename — texture will be in same dir as OBJ/MTL
                f.write(f'map_Kd {tex}\n')
                print(f"    {mat!r:40s} → {tex}")
            else:
                unmapped.append(mat)
                print(f"    {mat!r:40s} → [NO MATCH — will be grey]")

    if unmapped:
        print(f"  [WARNING] {len(unmapped)} material(s) had no matching texture.")
        print( "           Available textures:")
        for t in tex_files:
            print(f"             {t}")

    return mtl_path


def inject_textures_into_dae(dae_path, tex_dir, tex_files):
    """
    Sketchfab DAE exports have no <library_images> — the COLLADA file contains
    only a solid white diffuse color, and the PBR textures live in a separate
    textures/ folder unreferenced.

    This function:
    1. Finds the albedo/basecolor texture in tex_files
    2. Copies it alongside the DAE
    3. Patches the COLLADA XML to wire it up as the diffuse texture
    Returns True if the patch was applied, False otherwise.
    """
    import xml.etree.ElementTree as ET

    ET.register_namespace('', 'http://www.collada.org/2005/11/COLLADASchema')
    tree = ET.parse(dae_path)
    root = tree.getroot()
    ns = 'http://www.collada.org/2005/11/COLLADASchema'

    # Skip if library_images already exists (textures already referenced)
    if root.find(f'{{{ns}}}library_images') is not None:
        return False

    # Find the best albedo/diffuse/basecolor texture
    priority = ('albedo', 'basecolor', 'base_color', 'diffuse', '_col', 'color')
    albedo = None
    for kw in priority:
        for tex in tex_files:
            if kw in tex.lower():
                albedo = tex
                break
        if albedo:
            break
    if not albedo:
        print("  [WARNING] No albedo/color texture found — DAE will remain untextured.")
        return False

    print(f"  Injecting texture into DAE: {albedo}")

    # Copy texture alongside the DAE so paths resolve correctly
    src = os.path.join(tex_dir, albedo)
    dst = os.path.join(os.path.dirname(dae_path), albedo)
    if not os.path.exists(dst):
        shutil.copy2(src, dst)

    img_id      = 'injected_albedo'
    surface_sid = 'injected_albedo-surface'
    sampler_sid = 'injected_albedo-sampler'

    # ── 1. Add <library_images> before <library_effects> ────
    lib_effects_el = root.find(f'{{{ns}}}library_effects')
    if lib_effects_el is None:
        print("  [WARNING] No <library_effects> found in DAE — cannot inject texture.")
        return False

    lib_images_el = ET.Element(f'{{{ns}}}library_images')
    image_el      = ET.SubElement(lib_images_el, f'{{{ns}}}image')
    image_el.set('id',   img_id)
    image_el.set('name', img_id)
    init_el       = ET.SubElement(image_el, f'{{{ns}}}init_from')
    init_el.text  = albedo    # filename only — texture is in same dir as DAE

    root.insert(list(root).index(lib_effects_el), lib_images_el)

    # ── 2. Patch each effect: add surface+sampler params, swap diffuse ──
    for effect_el in root.iter(f'{{{ns}}}effect'):
        profile_el = effect_el.find(f'{{{ns}}}profile_COMMON')
        if profile_el is None:
            continue

        # Insert newparam: surface
        p_surf = ET.SubElement(profile_el, f'{{{ns}}}newparam')
        p_surf.set('sid', surface_sid)
        surf_el = ET.SubElement(p_surf, f'{{{ns}}}surface')
        surf_el.set('type', '2D')
        ET.SubElement(surf_el, f'{{{ns}}}init_from').text = img_id

        # Insert newparam: sampler2D
        p_samp = ET.SubElement(profile_el, f'{{{ns}}}newparam')
        p_samp.set('sid', sampler_sid)
        samp_el = ET.SubElement(p_samp, f'{{{ns}}}sampler2D')
        ET.SubElement(samp_el, f'{{{ns}}}source').text = surface_sid

        # In the technique, replace <diffuse><color> with <diffuse><texture>
        tech_el = profile_el.find(f'{{{ns}}}technique')
        if tech_el is None:
            continue
        for shader_el in list(tech_el):
            diffuse_el = shader_el.find(f'{{{ns}}}diffuse')
            if diffuse_el is None:
                continue
            for child in list(diffuse_el):
                diffuse_el.remove(child)
            tex_ref = ET.SubElement(diffuse_el, f'{{{ns}}}texture')
            tex_ref.set('texture',  sampler_sid)
            tex_ref.set('texcoord', 'TEX0')

    tree.write(dae_path, encoding='unicode', xml_declaration=True)
    return True


def check_existing_mtl(obj_path):
    """
    If an MTL exists, check whether its texture references resolve.
    Returns (mtl_path, is_broken).
    """
    mtl_path = os.path.splitext(obj_path)[0] + '.mtl'
    if not os.path.isfile(mtl_path):
        return None, False  # no MTL at all

    obj_dir = os.path.dirname(obj_path)
    broken = False
    with open(mtl_path, 'r', errors='replace') as f:
        for line in f:
            if line.strip().lower().startswith('map_kd'):
                parts = line.strip().split(None, 1)
                if len(parts) == 2:
                    tex_ref = parts[1].strip()
                    resolved = os.path.join(obj_dir, tex_ref)
                    if not os.path.isfile(resolved):
                        broken = True
                        break
    return mtl_path, broken


def convert(input_path, output_path=None, base_dir=None):
    try:
        import trimesh
    except ImportError:
        print("[ERROR] trimesh not installed. Run: pip3 install trimesh[easy] --user")
        return False

    input_path = os.path.realpath(input_path)
    if not os.path.isfile(input_path):
        print(f"[ERROR] File not found: {input_path}")
        return False

    ext = os.path.splitext(input_path)[1].lower()
    if ext not in ('.obj', '.dae'):
        print(f"[ERROR] Unsupported input: {ext}  (supported: .obj .dae)")
        return False

    if output_path is None:
        output_path = os.path.splitext(input_path)[0] + '.glb'
    output_path = os.path.realpath(output_path)

    obj_dir = os.path.dirname(input_path)

    # ── Determine base_dir ───────────────────────────────────
    if base_dir is None:
        print()
        print("  Sketchfab downloads separate mesh and textures into different folders:")
        print("    download-folder/")
        print("    ├── source/")
        print("    │   └── model.obj   ← your mesh")
        print("    └── textures/       ← textures are here")
        print()
        print(f"  Mesh file: {input_path}")
        print()
        base_dir = input("  Enter the root download folder (parent of textures/): ").strip()
        if base_dir.startswith('~'):
            base_dir = os.path.expanduser(base_dir)
        base_dir = os.path.realpath(base_dir)

    if not os.path.isdir(base_dir):
        print(f"  [WARNING] Base dir not found: {base_dir} — will look for textures relative to mesh.")
        base_dir = obj_dir

    # ── Find textures directory ───────────────────────────────
    tex_dir = find_textures_dir(base_dir, obj_dir)
    if tex_dir:
        tex_files = list_texture_files(tex_dir)
        print(f"  Textures folder: {tex_dir}  ({len(tex_files)} images)")
    else:
        tex_files = []
        print(f"  [WARNING] No textures/ folder found under: {base_dir}")

    # ── Check / build MTL (OBJ only) ─────────────────────────
    copied_textures = []
    created_mtl = None

    if ext == '.obj':
        existing_mtl, is_broken = check_existing_mtl(input_path)

        if existing_mtl and not is_broken:
            print(f"  MTL found and valid: {existing_mtl}")
        else:
            if existing_mtl and is_broken:
                print(f"  MTL exists but texture paths are broken — rebuilding.")
                os.remove(existing_mtl)

            if tex_files:
                # Copy textures to same dir as OBJ so trimesh can find them
                print(f"  Copying {len(tex_files)} texture(s) alongside OBJ...")
                for tex in tex_files:
                    src = os.path.join(tex_dir, tex)
                    dst = os.path.join(obj_dir, tex)
                    if not os.path.exists(dst):
                        shutil.copy2(src, dst)
                        copied_textures.append(dst)
                    # else already there (from previous run)

                created_mtl = build_mtl(input_path, tex_dir, tex_files)
            else:
                print("  [WARNING] No textures found — GLB will have no colors.")

    # ── For .dae: inject albedo texture into a temp copy ────────
    # Sketchfab DAE exports omit <library_images>. Rather than patching the
    # original file, we patch a temporary copy so the source is never touched.
    load_path = input_path   # may be replaced by the patched temp copy
    temp_dae  = None

    if ext == '.dae' and tex_files:
        temp_dae = input_path + '._patched_tmp.dae'
        shutil.copy2(input_path, temp_dae)
        patched = inject_textures_into_dae(temp_dae, tex_dir, tex_files)
        if patched:
            load_path = temp_dae
            # The texture was copied alongside temp_dae (same dir as input_path)
            albedo_kw = ('albedo', 'basecolor', 'base_color', 'diffuse', '_col', 'color')
            for tex in tex_files:
                if any(k in tex.lower() for k in albedo_kw):
                    dst = os.path.join(os.path.dirname(input_path), tex)
                    if dst not in copied_textures and os.path.exists(dst):
                        copied_textures.append(dst)
                    break
        else:
            # Patch failed — remove temp and use original
            os.remove(temp_dae)
            temp_dae = None

    # ── Convert with trimesh ──────────────────────────────────
    print(f"  Loading {ext}...")
    try:
        scene = trimesh.load(load_path, force='scene')
    except Exception as e:
        print(f"[ERROR] trimesh failed to load: {e}")
        if temp_dae and os.path.exists(temp_dae):
            os.remove(temp_dae)
        _cleanup(copied_textures, created_mtl)
        return False

    if not isinstance(scene, trimesh.Scene):
        scene = trimesh.Scene(geometry={'mesh': scene})

    # Report texture status — handle both SimpleMaterial.image and PBRMaterial.baseColorTexture
    textured = 0
    for name, mesh in scene.geometry.items():
        v = getattr(mesh, 'visual', None)
        if v and hasattr(v, 'material'):
            mat = v.material
            img = getattr(mat, 'baseColorTexture', None) or getattr(mat, 'image', None)
            if img and getattr(img, 'size', (0, 0)) not in [(1, 1), (2, 2)]:
                textured += 1

    total = len(scene.geometry)
    if textured == 0:
        if ext == '.dae':
            print(f"  [WARNING] DAE has no <library_images> — no textures to embed.")
            print( "           Re-download as .glb from Sketchfab for full PBR textures.")
        else:
            print(f"  [WARNING] Textures not embedded ({total} meshes, 0 textured).")
    else:
        print(f"  Textures embedded: {textured}/{total} meshes  ✓")

    # ── Center the model at the origin ───────────────────────
    # Photogrammetry scans and many real-world exports have large coordinate
    # offsets — their origin (0,0,0) is nowhere near the actual geometry.
    # This causes models placed at (15,0,0) in Gazebo to appear black or
    # invisible because the actual mesh is hundreds of meters away.
    # Fix: translate so the model's XY center and Z bottom sit at (0,0,0).
    import numpy as np
    try:
        bounds = scene.bounds          # shape (2, 3): [min_xyz, max_xyz]
        if bounds is not None:
            center = bounds.mean(axis=0)   # XYZ center of bounding box
            center[2] = bounds[0, 2]       # keep Z offset: bottom of model at Z=0
            offset = np.array([-center[0], -center[1], -center[2]])
            scene.apply_transform(
                trimesh.transformations.translation_matrix(offset)
            )
            print(f"  Centered: shifted by {offset.round(2)}  (bottom at Z=0)")
    except Exception as e:
        print(f"  [WARNING] Could not center model: {e}")

    # ── Export GLB ────────────────────────────────────────────
    try:
        scene.export(output_path)
        size_kb = os.path.getsize(output_path) // 1024
        print(f"  Exported: {output_path}  ({size_kb} KB)")
    except Exception as e:
        print(f"[ERROR] Export failed: {e}")
        _cleanup(copied_textures, created_mtl)
        return False

    # ── Fix material names in the GLB for Gazebo/OGRE2 ───────
    # trimesh doesn't carry MTL material names into GLTF — all materials get
    # an empty name. OGRE2 uses names as keys, so unnamed materials collapse
    # into one and only the first texture is shown on all meshes.
    fix_material_names(output_path)

    if temp_dae and os.path.exists(temp_dae):
        os.remove(temp_dae)
    _cleanup(copied_textures, created_mtl)
    return True


def fix_material_names(glb_path):
    """
    Gazebo/OGRE2 identifies materials by name. When all materials have an empty
    name (trimesh doesn't carry MTL names into GLTF), OGRE2 creates a single
    material object for all of them and applies only the first texture everywhere.
    Fix: copy each mesh's name into its material's 'name' field in the GLTF JSON.
    """
    import struct, json

    with open(glb_path, 'rb') as f:
        raw = bytearray(f.read())

    # GLB layout: 12-byte header | chunk0_len(4) chunk0_type(4) json(chunk0_len) | bin chunk
    chunk0_len = struct.unpack_from('<I', raw, 12)[0]
    json_start = 20                        # 12 (header) + 4 (len) + 4 (type)
    json_end   = json_start + chunk0_len

    gltf = json.loads(raw[json_start:json_end])

    # Build material_index → name from mesh primitives
    mat_names = {}
    for mesh in gltf.get('meshes', []):
        name = mesh.get('name', '').strip()
        for prim in mesh.get('primitives', []):
            idx = prim.get('material')
            if idx is not None and name and idx not in mat_names:
                mat_names[idx] = name

    if not mat_names:
        return  # nothing to do

    changed = 0
    for i, mat in enumerate(gltf.get('materials', [])):
        if not mat.get('name') and i in mat_names:
            mat['name'] = mat_names[i]
            changed += 1

    if changed == 0:
        return

    # Re-encode JSON; pad to 4-byte boundary with spaces (GLTF spec)
    new_json = json.dumps(gltf, separators=(',', ':')).encode('utf-8')
    while len(new_json) % 4:
        new_json += b' '

    diff = len(new_json) - chunk0_len
    struct.pack_into('<I', raw, 12, len(new_json))             # update chunk0 length
    struct.pack_into('<I', raw, 8,  struct.unpack_from('<I', raw, 8)[0] + diff)  # total length

    with open(glb_path, 'wb') as f:
        f.write(raw[:json_start])
        f.write(new_json)
        f.write(raw[json_end:])

    print(f"  Material names fixed ({changed}): {list(mat_names.values())}")


def _cleanup(copied_textures, created_mtl):
    """Remove temporary files copied/created for conversion."""
    for f in copied_textures:
        if os.path.exists(f):
            os.remove(f)
    if created_mtl and os.path.exists(created_mtl):
        os.remove(created_mtl)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Convert .obj/.dae to .glb with textures embedded.')
    parser.add_argument('input', help='Path to .obj or .dae file')
    parser.add_argument('output', nargs='?', help='Output .glb path (default: same dir)')
    parser.add_argument('--base-dir', help='Root download folder (parent of textures/)')
    args = parser.parse_args()

    ok = convert(args.input, args.output, args.base_dir)
    sys.exit(0 if ok else 1)
