$fn=100;
$fs=0.5;
SLED_X = 64.95;
SLED_Y = 84;
SLED_Z = 4.75;
RAIL_X = 3.1;
RAIL_Z = 8.84 - SLED_Z;
BANDIT_W = 20;
BANDIT_L = 125;
BANDIT_Z = 5;
BANDIT_RW = 1;
BANDIT_RZ = 5;
SCREW_SPACING = 25;
SCREW_ID = 9.5;

difference() {
    union() {
        // tripod sled
        translate([-SLED_X/2, -SLED_Y/2, -SLED_Z]) {
            cube([SLED_X, SLED_Y, SLED_Z]);
            translate([0, 0, -RAIL_Z]) {
                cube([RAIL_X, SLED_Y, RAIL_Z]);
                translate([SLED_X-RAIL_X, 0, 0]) cube([RAIL_X, SLED_Y, RAIL_Z]);
            }
        }

        // BANDIT mount
        // y-axis mount
        bandit_effw = BANDIT_W + 2*BANDIT_RW;
        translate([-bandit_effw/2, -BANDIT_L/2, 0]) {
            cube([bandit_effw, BANDIT_L, BANDIT_Z]);
            difference() {
                union() {
                    translate([0, 0, BANDIT_Z]) cube([BANDIT_RW, BANDIT_L, BANDIT_RZ]);
                    translate([BANDIT_W+BANDIT_RW, 0, BANDIT_Z]) cube([BANDIT_RW, BANDIT_L, BANDIT_RZ]);
                }
                translate([0, (BANDIT_L-bandit_effw)/2, BANDIT_Z]) cube([bandit_effw, bandit_effw, BANDIT_Z]);
            }
        }
        // x-axis mount
        translate([-BANDIT_L/2, -bandit_effw/2, 0]) {
            cube([BANDIT_L, bandit_effw, BANDIT_Z]);
            difference() {
                union() {
                    translate([0, 0, BANDIT_Z]) cube([BANDIT_L, BANDIT_RW, BANDIT_RZ]);
                    translate([0, BANDIT_W+BANDIT_RW, BANDIT_Z]) cube([BANDIT_L, BANDIT_RW, BANDIT_RZ]);
                }
                translate([(BANDIT_L-BANDIT_W)/2, 0, BANDIT_Z]) cube([bandit_effw-2*BANDIT_RW, bandit_effw, BANDIT_Z]);
            }
        }
    }
    union() {
        //screw cutouts
        screw_bottom = -(SLED_Z + RAIL_Z);
        screw_top = BANDIT_Z + BANDIT_RZ;
        screw_height = screw_top - screw_bottom;
        for (i=[0:2]) {
            translate([-SCREW_SPACING*i, 0, screw_bottom]) cylinder(h=screw_height, r=SCREW_ID/2);
            translate([SCREW_SPACING*i, 0, screw_bottom]) cylinder(h=screw_height, r=SCREW_ID/2);
            translate([0, -SCREW_SPACING*i, screw_bottom]) cylinder(h=screw_height, r=SCREW_ID/2);
            translate([0, SCREW_SPACING*i, screw_bottom]) cylinder(h=screw_height, r=SCREW_ID/2);
        }
    }
}
