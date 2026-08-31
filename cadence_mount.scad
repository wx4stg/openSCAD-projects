// Mount for cateye strada cadence sensor (zip tie)
// Created 30 August 2026 by Sam Gardner <sam@wx4stg.com>

inner_x = 21.65;
iouter_x = 25;
inner_y = 21.133;
iouter_y = 25;
plate_depth = 5;

ziptie_x_inset = 3;
ziptie_y_inset = 3;
ziptie_x = 2;
ziptie_y = 5;

extension_plate_x = 3*ziptie_x;
extension_plate_y = (ziptie_y + ziptie_y_inset);

outer_x = iouter_x + 2*extension_plate_x;
outer_y = iouter_y + 2*extension_plate_y;

difference() {
    // Outer shell
    cube([outer_x, outer_y, plate_depth]);
    union() {
        // Inner cavity
        translate([(outer_x - inner_x)/2, ((outer_y - extension_plate_y) - inner_y)/2, 0]) cube([inner_x, outer_y, plate_depth + 1]);
        // Zip tie holes
        translate([ziptie_x_inset, ziptie_y_inset, 0]) cube([ziptie_x, ziptie_y, plate_depth + 1]);
        translate([(outer_x - ziptie_x_inset - ziptie_x), ziptie_y_inset, 0]) cube([ziptie_x, ziptie_y, plate_depth + 1]);
        translate([ziptie_x_inset, outer_y - ziptie_y_inset - ziptie_y, 0]) cube([ziptie_x, ziptie_y, plate_depth + 1]);
        translate([(outer_x - ziptie_x_inset - ziptie_x), outer_y - ziptie_y_inset - ziptie_y, 0]) cube([ziptie_x, ziptie_y, plate_depth + 1]);

    }
}