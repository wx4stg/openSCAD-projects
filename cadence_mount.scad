// Mount for cateye strada cadence sensor (zip tie)
// Created 30 August 2026 by Sam Gardner <sam@wx4stg.com>

inner_x = 21.65;
outer_x = 25;
inner_y = 21.133;
outer_y = 25;
plate_depth = 5;

ziptie_x_inset = 3;
ziptie_x = 2;
ziptie_y = 5;

extension_plate_y = 1.5*ziptie_y;

difference() {
    // Outer shell
    cube([outer_x, outer_y, plate_depth]);
    // Inner cavity
    translate([(outer_x - inner_x)/2, (outer_y - inner_y)/2, 0]) cube([inner_x, inner_y, plate_depth + 1]);
}

translate([0, outer_y, 0]) {
    difference() {
        cube([outer_x, extension_plate_y, plate_depth]);
        union() {
            translate([ziptie_x_inset, (extension_plate_y - ziptie_y)/2, 0]) cube([ziptie_x, ziptie_y, plate_depth + 1]);
            translate([outer_x - ziptie_x_inset - ziptie_x, (extension_plate_y - ziptie_y)/2, 0]) cube([ziptie_x, ziptie_y, plate_depth + 1]);
        }
    }
}

translate([0, -extension_plate_y, 0]) {
    difference() {
        cube([outer_x, extension_plate_y, plate_depth]);
        union() {
            translate([ziptie_x_inset, (extension_plate_y - ziptie_y)/2, 0]) cube([ziptie_x, ziptie_y, plate_depth + 1]);
            translate([outer_x - ziptie_x_inset - ziptie_x, (extension_plate_y - ziptie_y)/2, 0]) cube([ziptie_x, ziptie_y, plate_depth + 1]);
        }
    }
}