#!/usr/bin/env python3
"""Turn a layered SVG into a multi-color OpenSCAD model and an Orca Slicer 3MF.

Each top-level <g id="..."> in the SVG is a layer; later layers are drawn on
top, so each layer has every later layer's footprint cut out of it and no two
parts overlap. You're asked for each layer's height, color and outline width.
The script then writes an OpenSCAD file that imports the layers straight from
the SVG, and a 3MF that Orca opens as one object with one part per layer and
one filament slot per distinct color.

Usage:
    python3 svg2orca.py drawing.svg [-o model.scad]   # prompts, writes .scad + .3mf
    python3 svg2orca.py model.scad                    # rebuild .3mf from an edited .scad

Needs an OpenSCAD nightly (SVG import by id, lazy-union, colored 3MF export).
Set $OPENSCAD to its path if it isn't found automatically.
"""
import argparse
import glob
import os
import re
import shutil
import subprocess
import sys
import tempfile
import uuid
import xml.etree.ElementTree as ET
import zipfile

SVG_NS = "http://www.w3.org/2000/svg"
CORE = "http://schemas.microsoft.com/3dmanufacturing/core/2015/02"
NS_3MF = {"c": CORE}
DRAWABLE = {"path", "line", "polyline", "polygon", "rect", "circle", "ellipse"}
CLOSED_SHAPES = {"polygon", "rect", "circle", "ellipse"}
NAMED_COLORS = {"black": "#000000", "white": "#FFFFFF", "red": "#FF0000",
                "green": "#008000", "blue": "#0000FF", "yellow": "#FFFF00"}


# ---------------------------------------------------------------- SVG layers

def local(tag):
    return tag.rsplit("}", 1)[-1]


def parse_css(root):
    """Return {class name: {property: value}} from the SVG's <style> blocks."""
    classes = {}
    for style in root.iter("{%s}style" % SVG_NS):
        for selectors, body in re.findall(r"([^{}]+)\{([^}]*)\}", style.text or ""):
            props = parse_declarations(body)
            for sel in selectors.split(","):
                sel = sel.strip()
                if sel.startswith("."):
                    classes.setdefault(sel[1:], {}).update(props)
    return classes


def parse_declarations(text):
    props = {}
    for decl in text.split(";"):
        if ":" in decl:
            key, value = decl.split(":", 1)
            props[key.strip()] = value.strip()
    return props


def element_style(elem, classes, inherited):
    """Presentation attributes < CSS classes < inline style, on top of inherited."""
    style = dict(inherited)
    for key in ("fill", "stroke", "stroke-width", "display"):
        if elem.get(key) is not None:
            style[key] = elem.get(key)
    for cls in (elem.get("class") or "").split():
        style.update(classes.get(cls, {}))
    style.update(parse_declarations(elem.get("style") or ""))
    return style


def to_hex(color):
    color = (color or "").strip().lower()
    if color in NAMED_COLORS:
        return NAMED_COLORS[color]
    if re.fullmatch(r"#[0-9a-f]{3}", color):
        return "#" + "".join(c * 2 for c in color[1:]).upper()
    if re.fullmatch(r"#[0-9a-f]{6}", color):
        return color.upper()
    return None


def is_closed(elem):
    tag = local(elem.tag)
    if tag in CLOSED_SHAPES:
        return True
    return tag == "path" and bool(re.search(r"[zZ]\s*$", elem.get("d") or ""))


def mm_per_unit(root):
    """Size of one SVG user unit in mm, matching OpenSCAD's import scaling."""
    unit_mm = {"px": 25.4 / 96, "mm": 1.0, "cm": 10.0, "in": 25.4,
               "pt": 25.4 / 72, "pc": 25.4 / 6, "": 25.4 / 72}
    view_box = (root.get("viewBox") or "").replace(",", " ").split()
    match = re.fullmatch(r"\s*([\d.]+)\s*([a-z]*)\s*", root.get("width") or "")
    if match and match.group(2) in unit_mm:
        width_mm = float(match.group(1)) * unit_mm[match.group(2)]
        return width_mm / float(view_box[2]) if len(view_box) == 4 else unit_mm[match.group(2)]
    return 25.4 / 72


def read_layers(svg_path):
    """Return a list of layer dicts in paint order (bottom first)."""
    root = ET.parse(svg_path).getroot()
    classes = parse_css(root)
    scale = mm_per_unit(root)
    root_style = element_style(root, classes, {"fill": "#000000"})

    layers = []
    for child in root:
        tag = local(child.tag)
        if tag in DRAWABLE:
            print("warning: skipping a <%s> outside any layer group" % tag, file=sys.stderr)
        if tag != "g":
            continue
        if not child.get("id"):
            print("warning: skipping a layer group with no id", file=sys.stderr)
            continue

        group_style = element_style(child, classes, root_style)
        shapes = []  # (style, closed) for each drawable element in the layer
        stack = [(child, group_style)]
        while stack:
            elem, style = stack.pop()
            for sub in elem:
                sub_style = element_style(sub, classes, style)
                if local(sub.tag) == "g":
                    stack.append((sub, sub_style))
                elif local(sub.tag) in DRAWABLE:
                    shapes.append((sub_style, is_closed(sub)))

        filled = [s for s, _ in shapes if s.get("fill", "#000000") != "none"]
        stroked = [s for s, _ in shapes if s.get("stroke", "none") != "none"]
        color = next((to_hex(s.get("fill")) for s in filled if to_hex(s.get("fill"))), None) \
            or next((to_hex(s.get("stroke")) for s in stroked if to_hex(s.get("stroke"))), None) \
            or "#808080"

        # OpenSCAD fills closed paths even when the SVG only strokes them, so
        # a layer of stroke-only closed shapes defaults to an outline instead.
        outline = 0.0
        if shapes and not filled and any(closed for _, closed in shapes):
            widths = [float(re.sub(r"[a-z]+$", "", s.get("stroke-width", "1")) or 1)
                      for s in stroked]
            outline = round(max(widths or [1.0]) * scale, 3)

        layers.append({
            "id": child.get("id"),
            "shapes": len(shapes),
            "hidden": group_style.get("display") == "none",
            "color": color,
            "outline": outline,
            "height": 1.0,
        })
    return layers


# ---------------------------------------------------------------- prompting

def ask(prompt, default, parse):
    while True:
        try:
            raw = input("  %s [%s]: " % (prompt, default)).strip()
        except EOFError:
            raw = ""
            print()
        if not raw:
            return parse(str(default))
        try:
            return parse(raw)
        except ValueError as e:
            print("    %s" % e)


def parse_height(text):
    value = float(text)
    if value < 0:
        raise ValueError("height can't be negative")
    return value


def parse_width(text):
    value = float(text)
    if value < 0:
        raise ValueError("outline width can't be negative")
    return value


def parse_color(text):
    color = to_hex(text if text.startswith("#") else "#" + text)
    if not color:
        raise ValueError("enter a hex color like #FFC800 or FC0")
    return color


def prompt_layers(layers):
    print("Layers, bottom to top. Later layers cover earlier ones.")
    print("Height 0 skips a layer. Outline 0 keeps shapes filled as drawn.\n")
    for n, layer in enumerate(layers, start=1):
        note = " (hidden in SVG)" if layer["hidden"] else ""
        print("[%d/%d] %s: %d shapes%s" % (n, len(layers), layer["id"], layer["shapes"], note))
        layer["height"] = ask("height (mm)", 0 if layer["hidden"] else layer["height"], parse_height)
        if layer["height"] == 0:
            continue
        layer["color"] = ask("color (hex)", layer["color"], parse_color)
        layer["outline"] = ask("outline width (mm)", layer["outline"], parse_width)
    return [l for l in layers if l["height"] > 0]


# ---------------------------------------------------------------- OpenSCAD

SCAD_TEMPLATE = """\
// Generated by svg2orca.py from {svg_name}.
// Rebuild the Orca 3MF after editing: python3 svg2orca.py {scad_name}

svg = "{svg_path}";

// [SVG layer id, height (mm), color, outline width (mm, 0 = filled as drawn)]
// Bottom to top: each layer covers the ones before it.
layers = [
{rows}
];

// Tiny offset that re-cleans the imported polygons (self-intersecting paths).
clean = 0.001;

// Line of the given width centered on the shape's edge.
module outline(width) {{
    difference() {{
        offset(r = width / 2) children();
        offset(r = -width / 2) children();
    }}
}}

module footprint(l) {{
    if (l[3] > 0) outline(l[3]) offset(delta = clean) import(svg, id = l[0]);
    else offset(delta = clean) import(svg, id = l[0]);
}}

// Footprint of layer i with every later layer cut out, so no two layers
// overlap and each region belongs to exactly one filament in the slicer.
module exclusive_footprint(i) {{
    difference() {{
        footprint(layers[i]);
        if (i < len(layers) - 1)
            for (j = [i + 1 : len(layers) - 1]) footprint(layers[j]);
    }}
}}

for (i = [0 : len(layers) - 1])
    color(layers[i][2])
        linear_extrude(height = layers[i][1])
            exclusive_footprint(i);
"""


def write_scad(layers, svg_path, scad_path):
    width = max(len(l["id"]) for l in layers) + 3
    rows = ",\n".join(
        '    [%s %g, "%s", %g]' % ((('"%s",' % l["id"]).ljust(width)),
                                   l["height"], l["color"], l["outline"])
        for l in layers)
    # Relative when the SVG sits beside or below the .scad, so the pair can move together.
    svg_ref = os.path.relpath(svg_path, os.path.dirname(os.path.abspath(scad_path)))
    if svg_ref.startswith(".."):
        svg_ref = os.path.abspath(svg_path)
    with open(scad_path, "w") as f:
        f.write(SCAD_TEMPLATE.format(
            svg_name=os.path.basename(svg_path), scad_name=scad_path,
            svg_path=svg_ref, rows=rows))


def find_openscad():
    if os.environ.get("OPENSCAD"):
        return os.environ["OPENSCAD"]
    nightlies = sorted(glob.glob(os.path.expanduser("~/Downloads/OpenSCAD-*.AppImage")))
    if nightlies:
        return nightlies[-1]
    if shutil.which("openscad"):
        return "openscad"
    sys.exit("OpenSCAD nightly not found; set $OPENSCAD to its path")


def export_scad(scad_path, out_3mf):
    result = subprocess.run(
        [find_openscad(), "--backend", "manifold", "--enable", "lazy-union",
         "-O", "export-3mf/color-mode=model", "-o", out_3mf, scad_path],
        capture_output=True, text=True)
    if result.returncode != 0 or not os.path.exists(out_3mf):
        sys.exit("OpenSCAD failed:\n" + result.stderr)
    for line in result.stderr.splitlines():
        if "WARNING" in line or "ERROR" in line:
            print(line, file=sys.stderr)


def scad_layer_names(scad_path):
    """Layer ids from a generated .scad's layers table, for naming the parts."""
    with open(scad_path) as f:
        table = re.search(r"^layers\s*=\s*\[(.*?)^\];", f.read(), re.S | re.M)
    return re.findall(r'^\s*\[\s*"([^"]+)"', table.group(1), re.M) if table else []


# ---------------------------------------------------------------- Orca 3MF

def read_openscad_3mf(path):
    """Return [(color_hex, vertices_xml, triangles_xml)] for each mesh object."""
    with zipfile.ZipFile(path) as z:
        root = ET.fromstring(z.read("3D/3dmodel.model"))

    colors = {}  # basematerials id -> [displaycolor, ...]
    for bm in root.iterfind(".//c:basematerials", NS_3MF):
        colors[bm.get("id")] = [b.get("displaycolor", "#808080FF")[:7]
                                for b in bm.iterfind("c:base", NS_3MF)]

    parts = []
    for obj in root.iterfind(".//c:object", NS_3MF):
        mesh = obj.find("c:mesh", NS_3MF)
        if mesh is None:
            continue
        # Color is the object default unless (most of) its triangles override it.
        pid, pindex = obj.get("pid"), obj.get("pindex", "0")
        votes = {}
        tris = []
        for t in mesh.iterfind("c:triangles/c:triangle", NS_3MF):
            key = (t.get("pid", pid), t.get("p1", pindex))
            votes[key] = votes.get(key, 0) + 1
            tris.append('<triangle v1="%s" v2="%s" v3="%s"/>'
                        % (t.get("v1"), t.get("v2"), t.get("v3")))
        if votes:
            pid, pindex = max(votes, key=votes.get)
        color = colors.get(pid, ["#808080"])[int(pindex)] if pid else "#808080"
        verts = ['<vertex x="%s" y="%s" z="%s"/>' % (v.get("x"), v.get("y"), v.get("z"))
                 for v in mesh.iterfind("c:vertices/c:vertex", NS_3MF)]
        parts.append((color, verts, tris))
    return parts


def write_orca_3mf(parts, names, path, name):
    slots = []  # distinct colors, index + 1 = filament slot
    for color, _, _ in parts:
        if color not in slots:
            slots.append(color)

    object_id = len(parts) + 1
    meshes = []
    components = []
    settings = []
    for i, (color, verts, tris) in enumerate(parts, start=1):
        meshes.append(
            '<object id="%d" p:UUID="%s" type="model"><mesh><vertices>%s</vertices>'
            '<triangles>%s</triangles></mesh></object>'
            % (i, uuid.uuid4(), "".join(verts), "".join(tris)))
        components.append(
            '<component p:path="/3D/Objects/object_1.model" objectid="%d" p:UUID="%s" '
            'transform="1 0 0 0 1 0 0 0 1 0 0 0"/>' % (i, uuid.uuid4()))
        settings.append(
            '<part id="%d" subtype="normal_part">'
            '<metadata key="name" value="%s"/>'
            '<metadata key="matrix" value="1 0 0 0 0 1 0 0 0 0 1 0 0 0 0 1"/>'
            '<metadata key="extruder" value="%d"/></part>'
            % (i, xml_attr(names[i - 1]), slots.index(color) + 1))

    header = ('<?xml version="1.0" encoding="UTF-8"?>\n'
              '<model unit="millimeter" xml:lang="en-US" xmlns="%s" '
              'xmlns:BambuStudio="http://schemas.bambulab.com/package/2021" '
              'xmlns:p="http://schemas.microsoft.com/3dmanufacturing/production/2015/06" '
              'requiredextensions="p">\n' % CORE)
    main_model = (
        header +
        '<metadata name="Application">BambuStudio-01.10.00.00</metadata>\n'
        '<metadata name="BambuStudio:3mfVersion">1</metadata>\n'
        '<resources><object id="%d" p:UUID="%s" type="model"><components>%s'
        '</components></object></resources>\n'
        '<build p:UUID="%s"><item objectid="%d" p:UUID="%s" printable="1"/></build>\n'
        '</model>\n'
        % (object_id, uuid.uuid4(), "".join(components), uuid.uuid4(), object_id, uuid.uuid4()))
    object_model = header + "<resources>%s</resources><build/></model>\n" % "".join(meshes)
    model_settings = (
        '<?xml version="1.0" encoding="UTF-8"?>\n<config>\n'
        '<object id="%d"><metadata key="name" value="%s"/>'
        '<metadata key="extruder" value="1"/>%s</object>\n'
        '<plate><metadata key="plater_id" value="1"/>'
        '<model_instance><metadata key="object_id" value="%d"/>'
        '<metadata key="instance_id" value="0"/></model_instance></plate>\n'
        '</config>\n'
        % (object_id, xml_attr(name), "".join(settings), object_id))

    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("[Content_Types].xml",
                   '<?xml version="1.0" encoding="UTF-8"?>\n'
                   '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
                   '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
                   '<Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/>'
                   '</Types>')
        rel = ('<?xml version="1.0" encoding="UTF-8"?>\n'
               '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
               '<Relationship Target="%s" Id="rel-1" '
               'Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/></Relationships>')
        z.writestr("_rels/.rels", rel % "/3D/3dmodel.model")
        z.writestr("3D/_rels/3dmodel.model.rels", rel % "/3D/Objects/object_1.model")
        z.writestr("3D/3dmodel.model", main_model)
        z.writestr("3D/Objects/object_1.model", object_model)
        z.writestr("Metadata/model_settings.config", model_settings)
    return slots


def xml_attr(text):
    return (text.replace("&", "&amp;").replace('"', "&quot;")
            .replace("<", "&lt;").replace(">", "&gt;"))


def build_3mf(scad_path, out_3mf):
    with tempfile.TemporaryDirectory() as tmp:
        export = os.path.join(tmp, "export.3mf")
        export_scad(scad_path, export)
        parts = read_openscad_3mf(export)

    names = scad_layer_names(scad_path)
    if len(names) != len(parts):
        # A layer fully covered by later ones exports nothing, so the
        # layer table no longer lines up with the parts; fall back to colors.
        names = [color for color, _, _ in parts]
    name = os.path.splitext(os.path.basename(scad_path))[0]
    slots = write_orca_3mf(parts, names, out_3mf, name)

    print("wrote %s: %d parts" % (out_3mf, len(parts)))
    for slot, color in enumerate(slots, start=1):
        layers = [n for n, (c, _, _) in zip(names, parts) if c == color]
        print("  filament %d = %s  (%s)" % (slot, color, ", ".join(layers)))


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("input", help="layered .svg, or a .scad this script generated")
    ap.add_argument("-o", "--scad", help="OpenSCAD file to write (default: <svg name>.scad)")
    ap.add_argument("--3mf", dest="out_3mf", help="3MF to write (default: <scad name>_orca.3mf)")
    args = ap.parse_args()

    if args.input.endswith(".scad"):
        scad_path = args.input
    else:
        scad_path = args.scad or os.path.splitext(os.path.basename(args.input))[0] + ".scad"
        layers = read_layers(args.input)
        if not layers:
            sys.exit("no layers found: expected top-level <g id=\"...\"> groups")
        layers = prompt_layers(layers)
        if not layers:
            sys.exit("every layer was skipped")
        write_scad(layers, args.input, scad_path)
        print("\nwrote %s" % scad_path)

    build_3mf(scad_path, args.out_3mf or os.path.splitext(scad_path)[0] + "_orca.3mf")


if __name__ == "__main__":
    main()
