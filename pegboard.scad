// Generates pegboard
// Created 11 November 2026 by Sam Gardner <sam@wx4stg.com>

hole_spacing = 25.4;
hole_diameter = 6.35;
plate_thickness = 3.175;
plate_Lx = 80;
plate_Ly = 80;
edge_margin = 0;
hole_segments = 90;

function hole_count(len) =
    let(usable = len - hole_diameter - 2 * edge_margin)
    usable < 0 ? 0 : floor(usable / hole_spacing + 1e-6) + 1;

nx = hole_count(plate_Lx);
ny = hole_count(plate_Ly);

// Grid is centered on the plate
grid_w = (nx - 1) * hole_spacing;
grid_h = (ny - 1) * hole_spacing;
off_x = (plate_Lx - grid_w) / 2;
off_y = (plate_Ly - grid_h) / 2;

difference() {
    cube([plate_Lx, plate_Ly, plate_thickness]);
    for (i = [0 : nx - 1], j = [0 : ny - 1])
        translate([off_x + i * hole_spacing, off_y + j * hole_spacing, -1])
            cylinder(d = hole_diameter, h = plate_thickness + 2, $fn = hole_segments);
}
