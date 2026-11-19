// Alignment plate for DREVL instrument
// Created 18 September 2026 by Sam Gardner <samuel.gardner@ttu.edu>

$fn=100;
$fs=0.5;

PLATE_THICKNESS = 5;
PLATE_WIDTH = 80;
PLATE_HEIGHT = 80;

LEG_LENGTH = 32.2;

SCREW_PLATE_HEIGHT = 5;
SCREW_PLATE_THICKNESS = 20;
SCREW_DIAMETER = 6.89;
SCREW_SPACING = 25.48;

CENTER_HOLE_DIAMETER = 30;
CORNER_HOLE_DIAMETER = 20.745;//18.745;  // 17.8181
CORNER_HOLE_DISTANCE = 54.3/2;//53.8226/2; // 71.6407 edge to edge
START_OFFSET = 0;

center_hole_xy = (PLATE_WIDTH)/2;
difference() {
    // Outer plate
    cube([PLATE_WIDTH, PLATE_HEIGHT, PLATE_THICKNESS]);
    union() {
        // Center hole
        translate([center_hole_xy, center_hole_xy, 0]) cylinder(h=PLATE_THICKNESS, d=CENTER_HOLE_DIAMETER);
        // hexagon of corner holes
        for (i=[0:5]) {
            this_angle = (i*60 + START_OFFSET) % 360;
            x_translation = CORNER_HOLE_DISTANCE * cos(this_angle);
            y_translation = CORNER_HOLE_DISTANCE * sin(this_angle);
            translate([center_hole_xy + x_translation, center_hole_xy + y_translation, 0]) {
                cylinder(h=PLATE_THICKNESS, d=CORNER_HOLE_DIAMETER);
            }
        }
    }
}

translate([0, -(LEG_LENGTH), 0]) {
    difference() {
        union() {
            cube([PLATE_WIDTH, LEG_LENGTH, PLATE_THICKNESS]);
            cube([PLATE_WIDTH, SCREW_PLATE_HEIGHT, SCREW_PLATE_THICKNESS]);
        }
        union() {
            for (i=[-1:1]) {
                translate([PLATE_WIDTH/2 + i * SCREW_SPACING, SCREW_PLATE_HEIGHT+PLATE_THICKNESS/2, ((PLATE_THICKNESS+SCREW_PLATE_THICKNESS)/2)]) rotate([90, 0, 0]) cylinder(h=PLATE_THICKNESS*2, d=SCREW_DIAMETER);
            }
        }
    }
}