// Adapter for a cheap dashcam to fit in a GoPro mount.
// Created 15 October 2026 by Sam Gardner <sam@wx4stg.com>

$fn=100;

GP_TOOTH_THICKNESS = 3.0;
GP_TOOTH_WIDTH = 15.0;
GP_TOOTH_HEIGHT = 14.0;
GP_TOOTH_SEPARATION = 3.3;
GP_HOLE_DIAMETER = 5.1;

DASHCAM_TOOTH_THICKNESS = 5.0;
DASHCAM_TOOTH_WIDTH = 15.8;
DASHCAM_TOOTH_HEIGHT = 15.8;
DASHCAM_TOOTH_SEPARATION = 13.5;

// Teeth for the GoPro side of the mount
module gopro_tooth() {
    cube([GP_TOOTH_WIDTH, GP_TOOTH_THICKNESS, GP_TOOTH_HEIGHT/2]);
    translate([GP_TOOTH_WIDTH/2, GP_TOOTH_THICKNESS/2, GP_TOOTH_WIDTH/2]) rotate([90, 0, 0]) cylinder(h=GP_TOOTH_THICKNESS, r=GP_TOOTH_WIDTH/2, center=true);
}

module dashcam_tooth() {
    cube([DASHCAM_TOOTH_WIDTH, DASHCAM_TOOTH_THICKNESS, DASHCAM_TOOTH_HEIGHT/2]);
    translate([DASHCAM_TOOTH_WIDTH/2, DASHCAM_TOOTH_THICKNESS/2, 0]) rotate([90, 0, 0]) cylinder(h=DASHCAM_TOOTH_THICKNESS, r=DASHCAM_TOOTH_WIDTH/2, center=true);
}

// GoPro teeth and screw hole
HOLE_LENGTH = 2*GP_TOOTH_THICKNESS + GP_TOOTH_SEPARATION;
translate([-GP_TOOTH_WIDTH/2, -HOLE_LENGTH/2, 0]) {
    difference() {
        union() {
            gopro_tooth();
            translate([0, GP_TOOTH_THICKNESS + GP_TOOTH_SEPARATION, 0]) gopro_tooth();
        }
        translate([(GP_TOOTH_WIDTH/2), HOLE_LENGTH/2, GP_TOOTH_HEIGHT/2]) rotate([90, 0, 0]) cylinder(h=HOLE_LENGTH, r=GP_HOLE_DIAMETER/2, center=true);
    }
}

DASHCAM_HOLE_LENGTH = 2*DASHCAM_TOOTH_THICKNESS + DASHCAM_TOOTH_SEPARATION;
PLATE_X = max(GP_TOOTH_WIDTH, DASHCAM_TOOTH_WIDTH);
PLATE_Y = max(HOLE_LENGTH, DASHCAM_HOLE_LENGTH);
// Interposer plate
translate([-PLATE_X/2, -PLATE_Y/2, -5]) cube([PLATE_X, PLATE_Y, 5]);

// Dashcam teeth and screw hole
translate([-PLATE_X/2, -DASHCAM_HOLE_LENGTH/2, -(5 + DASHCAM_TOOTH_HEIGHT/2)]) {
    difference() {
        union() {
            dashcam_tooth();
            translate([0, DASHCAM_TOOTH_THICKNESS + DASHCAM_TOOTH_SEPARATION, 0]) dashcam_tooth();
        }
        translate([(DASHCAM_TOOTH_WIDTH/2), DASHCAM_HOLE_LENGTH/2, 0]) rotate([90, 0, 0]) cylinder(h=DASHCAM_HOLE_LENGTH, r=GP_HOLE_DIAMETER/2, center=true);
    }
}