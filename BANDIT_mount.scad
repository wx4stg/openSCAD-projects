// Tripod mount for BANDIT instrument
// Created 31 July 2026 by Sam Gardner <samuel.gardner@ttu.edu>

$fn=100;
$fs=0.5;
SLED_X = 64.95;
SLED_Y = 84;
SLED_Z = 4.75;
TEETH_Y_DISP = 8.4;
TOOTH_Y = 33.83;
TOOTH_Z = 12 - SLED_Z;
CATEAR_X = 7.64;
CATEAR_Y = 16.73;
CATEAR_T_X = 8.81;
GAP_Z = 3;

RAIL_X = 3.1;
RAIL_Z = 8.84 - SLED_Z;
BANDIT_W = 21;
BANDIT_L = 125;
BANDIT_Z = 5;
BANDIT_RW = 1;
BANDIT_RZ = 5;
SCREW_SPACING = 25;
SCREW_ID = 8.3;

ARM_END_R = 4;      // corner radius at the ends of the plus arms
FILLET_R = 8;       // fillet radius where the plus arms meet
PART_GAP = 10;      // spacing between parts when PART = "both"

// "both"      - plate and sled laid out flat for printing
// "plate"     - plus plate only, flat face down
// "sled"      - tripod sled only, flat face down
// "assembled" - both parts in their assembled positions (preview only)
PART = "sled";

bandit_effw = BANDIT_W + 2*BANDIT_RW;

module screw_holes() {
    screw_bottom = -(SLED_Z + TOOTH_Z);
    screw_top = BANDIT_Z + BANDIT_RZ;
    screw_height = screw_top - screw_bottom;
    for (i=[0:2]) {
        translate([-SCREW_SPACING*i, 0, screw_bottom]) cylinder(h=screw_height, r=SCREW_ID/2);
        translate([SCREW_SPACING*i, 0, screw_bottom]) cylinder(h=screw_height, r=SCREW_ID/2);
        translate([0, -SCREW_SPACING*i, screw_bottom]) cylinder(h=screw_height, r=SCREW_ID/2);
        translate([0, SCREW_SPACING*i, screw_bottom]) cylinder(h=screw_height, r=SCREW_ID/2);
    }
}

// tripod sled, occupies z <= 0
module sled() {
    difference() {
        translate([-SLED_X/2, -SLED_Y/2, -SLED_Z]) {
            cube([SLED_X, SLED_Y, SLED_Z]);
            translate([0, 0, -RAIL_Z]) {
                cube([RAIL_X, SLED_Y, RAIL_Z]);
                translate([SLED_X-RAIL_X, 0, 0]) cube([RAIL_X, SLED_Y, RAIL_Z]);
            }
            // tripod attachment teeth/ears
            translate([RAIL_X, TEETH_Y_DISP, -TOOTH_Z]) {
                difference() {
                    union() {
                            cube([SLED_X-2*RAIL_X, TOOTH_Y, TOOTH_Z]);
                            translate([0, TOOTH_Y, 0]) {
                                cube([CATEAR_X, CATEAR_Y, TOOTH_Z]);
                                translate([SLED_X-2*RAIL_X-CATEAR_X, 0, 0]) cube([CATEAR_X, CATEAR_Y, TOOTH_Z]);
                            }
                            translate([CATEAR_X, TOOTH_Y, 0]) {
                                linear_extrude(height=TOOTH_Z) polygon(points=[[0, 0], [0, CATEAR_Y], [CATEAR_T_X, 0]]);
                            }
                            translate([(SLED_X-2*RAIL_X-CATEAR_X-CATEAR_T_X), TOOTH_Y, 0]) {
                                linear_extrude(height=TOOTH_Z) polygon(points=[[0, 0], [CATEAR_T_X, CATEAR_Y], [CATEAR_T_X, 0]]);
                            }
                    }
                    color("cyan") translate([(CATEAR_X+CATEAR_T_X), TOOTH_Y, TOOTH_Z]) rotate([90, 90, 90]){
                        linear_extrude(height=(SLED_X-2*(RAIL_X+CATEAR_X+CATEAR_T_X))) polygon(points=[[0, 0], [0, -GAP_Z], [TOOTH_Z, 0]]);

                    }
                }
            }
        }
        screw_holes();
    }
}

// plus outline with the outer corners of the arm ends rounded
module plus_outline() {
    offset(r=ARM_END_R) offset(delta=-ARM_END_R) {
        square([bandit_effw, BANDIT_L], center=true);
        square([BANDIT_L, bandit_effw], center=true);
    }
}

// plus outline with the inside corners between the arms filleted
module plate_outline() {
    offset(r=-FILLET_R) offset(delta=FILLET_R) plus_outline();
}

// BANDIT plus plate, occupies z >= 0
module plate() {
    difference() {
        union() {
            linear_extrude(height=BANDIT_Z) plate_outline();
            intersection() {
                union() {
                    // y-axis rails
                    translate([-bandit_effw/2, -BANDIT_L/2, 0]) {
                        difference() {
                            union() {
                                translate([0, 0, BANDIT_Z]) cube([BANDIT_RW, BANDIT_L, BANDIT_RZ]);
                                translate([BANDIT_W+BANDIT_RW, 0, BANDIT_Z]) cube([BANDIT_RW, BANDIT_L, BANDIT_RZ]);
                            }
                            translate([0, (BANDIT_L-bandit_effw)/2, BANDIT_Z]) cube([bandit_effw, bandit_effw, BANDIT_Z]);
                        }
                    }
                    // x-axis rails
                    translate([-BANDIT_L/2, -bandit_effw/2, 0]) {
                        difference() {
                            union() {
                                translate([0, 0, BANDIT_Z]) cube([BANDIT_L, BANDIT_RW, BANDIT_RZ]);
                                translate([0, BANDIT_W+BANDIT_RW, BANDIT_Z]) cube([BANDIT_L, BANDIT_RW, BANDIT_RZ]);
                            }
                            translate([(BANDIT_L-BANDIT_W)/2, 0, BANDIT_Z]) cube([bandit_effw-2*BANDIT_RW, bandit_effw, BANDIT_Z]);
                        }
                    }
                }
                linear_extrude(height=BANDIT_Z+BANDIT_RZ) plus_outline();
            }
        }
        screw_holes();
    }
}

// sled flipped so its flat top face sits on the bed
module sled_print() {
    rotate([180, 0, 0]) sled();
}

if (PART == "plate") {
    plate();
} else if (PART == "sled") {
    sled_print();
} else if (PART == "assembled") {
    plate();
    sled();
} else {
    plate();
    translate([BANDIT_L/2 + PART_GAP + SLED_X/2, 0, 0]) sled_print();
}
