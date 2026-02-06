// Main outer shell
buck_length = 45;
// buck_depth = 15;
buck_depth = 5;
buck_width = 22;
casing_thickness = 2;

difference() {
    // Outer shell
    cube([buck_length, buck_width, buck_depth]);
    
    // Inner cavity
    translate([casing_thickness, casing_thickness, casing_thickness]) {
        // cube([buck_length - 2*casing_thickness, buck_width - 2*casing_thickness, buck_depth - 2*casing_thickness]);
        cube([buck_length - 2*casing_thickness, buck_width - 2*casing_thickness, 100]);

    }
}
