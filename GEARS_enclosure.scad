// Enclosure testing for the GEARS workshop
// Created 3 August 2026 by Sam Gardner <sam@wx4stg.com>


in = 25.4;
pad = in*1/16;
// Box shell options
DO_BOX = true;
DO_SEALED_LID = false;
DO_PERFORATED_LID = false;
// castle options
CASTLE_WIDTH = in*1/4;
CASTLE_HEIGHT = in*1/4;
CASTLE_SPACING = in*1/4;
// trianglual prism lid
LID_GAP = 2*pad;
LID_SKIRT_H = 1*in;
LID_ROOF_H = 2*in;


// triangluar prism with skirt shape
module lid_profile(w, skirt, ridge, drop = 0) {
    polygon([[0,-drop], [w,-drop], [w,skirt], [w/2,skirt+ridge], [0,skirt]]);
}

// extrude that shape along the y axis, handle rotation internally
module prism_y(depth) {
    translate([0, depth, 0]) rotate([90, 0, 0])
        linear_extrude(height = depth) children();
}

module castle_cuts(len, thickness) {
    total_length = CASTLE_WIDTH + CASTLE_SPACING;
    n_castles = floor((len + CASTLE_SPACING) / total_length);
    y_start = (len - (n_castles*total_length - CASTLE_SPACING)) / 2;
    for (i = [0 : n_castles-1]) {
        translate([-1, y_start + i*total_length, 4*in - CASTLE_HEIGHT])
            cube([thickness + 2, CASTLE_WIDTH, CASTLE_HEIGHT + 1]);
    }
}

// Box shell
if (DO_BOX) {
    box_w = 6*in + pad*2;

    difference() {
        cube([box_w, box_w, 4*in]);
        translate([pad, pad, pad]) cube([6*in, 6*in, 4*in]);
        castle_cuts(box_w, pad);
        translate([box_w - pad, 0, 0]) castle_cuts(box_w, pad);
    }
}

// sealed lid
if (DO_SEALED_LID) {
    translate([-2*pad, -2*pad, 3*in]) {
        difference() {
            cube([6*in+6*pad, 6*in+6*pad, 1*in]);
            translate([pad, pad, 0]) cube([6*in+4*pad, 6*in+4*pad, 1*in-pad]);
        }
    }
}

// triangular prism lid
if (DO_PERFORATED_LID) {
    box_w   = 6*in + pad*2;
    lid_in  = box_w + 2*LID_GAP;
    lid_out = lid_in + 2*pad;
    translate([-(LID_GAP+pad), -(LID_GAP+pad), 4*in - LID_SKIRT_H]) {
        difference() {
            prism_y(lid_out) lid_profile(lid_out, LID_SKIRT_H, LID_ROOF_H);
            translate([0, pad, 0]) prism_y(lid_in)
                offset(delta = -pad)
                    lid_profile(lid_out, LID_SKIRT_H, LID_ROOF_H, drop = 4*pad);
        }
    }
}