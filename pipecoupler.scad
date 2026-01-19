// Pipe coupler for Yagi antenna mast
// Created 31 December 2025 by Sam Gardner <sam@wx4stg.com>

// Parameters
$fn = 100;
COUPLER_LENGTH = 45;
THICK = 5;
P_OD = 27;
M_OD = 22;
SCREW_DIAMETER = 5;
TAPE_MEASUREW = 21;
TAPE_MEASUREH = 7;
PVC_TM_GUIDE = false;
M_TM_GUIDE = false;


// PVC pipe side
if (!M_TM_GUIDE) {
    difference() {
        cylinder(h=COUPLER_LENGTH, r=(P_OD/2)+THICK, center=true);
        union() {
            cylinder(h=COUPLER_LENGTH, r=P_OD/2, center=true);
            rotate([90, 0, 0]) cylinder(h=100, r=SCREW_DIAMETER/2, center=true);
        }
    }
    // PVC tape measure guide
    if (PVC_TM_GUIDE) {
        translate([(P_OD/2), -(TAPE_MEASUREW/2+THICK), -COUPLER_LENGTH/2]) cube([THICK, TAPE_MEASUREW+THICK*2, COUPLER_LENGTH]);
        translate([(P_OD/2), -(TAPE_MEASUREW/2+2*THICK), -COUPLER_LENGTH/2]) cube([TAPE_MEASUREH+THICK, THICK, COUPLER_LENGTH]);
        translate([(P_OD/2), (TAPE_MEASUREW/2+THICK), -COUPLER_LENGTH/2]) cube([TAPE_MEASUREH+THICK, THICK, COUPLER_LENGTH]);
        translate([-((P_OD/2)+2*THICK), -(TAPE_MEASUREW/2+THICK), -COUPLER_LENGTH/2]) cube([2*THICK, TAPE_MEASUREW+THICK*2, COUPLER_LENGTH]);
    }
}

if (!PVC_TM_GUIDE) {
    // Metal pipe side
    rotate([90, 0, 0]) translate([(P_OD/2)+(M_OD/2)+THICK,0,0]) {
        difference() {
            cylinder(h=COUPLER_LENGTH, r=M_OD/2+THICK, center=true);
            cylinder(h=COUPLER_LENGTH, r=M_OD/2, center=true);
        }
        // Metal tape measure guide
        if (M_TM_GUIDE) {
            translate([(M_OD/2), -(TAPE_MEASUREW/2+THICK), -COUPLER_LENGTH/2]) cube([THICK, TAPE_MEASUREW+THICK*2, COUPLER_LENGTH]);
            translate([(M_OD/2), -(TAPE_MEASUREW/2+2*THICK), -COUPLER_LENGTH/2]) cube([TAPE_MEASUREH+THICK, THICK, COUPLER_LENGTH]);
            translate([(M_OD/2), (TAPE_MEASUREW/2+THICK), -COUPLER_LENGTH/2]) cube([TAPE_MEASUREH+THICK, THICK, COUPLER_LENGTH]);
            translate([-((M_OD/2)+2*THICK), -(TAPE_MEASUREW/2+THICK), -COUPLER_LENGTH/2]) cube([2*THICK, TAPE_MEASUREW+THICK*2, COUPLER_LENGTH]);
        }
    }
}