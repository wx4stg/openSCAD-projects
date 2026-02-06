// Buck converter housing for TTU lightning's WT-SANTA instrument
// Created 5 Februrary 2026 by Sam Gardner <samuel.gardner@ttu.edu>

// Parameters (all dimensions in mm)
buck_length = 45;
buck_depth = 10;
lid_depth = 5;
buck_width = 22;
casing_thickness = 2;

cable_cavity_length = 20;
cable_inset_width = 0.4;
wire_length_internal = 15;
wire_diameter = 3.4;



// Bottom half
difference() {
    // Outer shell
    cube([buck_length + cable_cavity_length + 2*casing_thickness, buck_width + 2*casing_thickness, (buck_depth-lid_depth)]);
    
    union() {
        // Inner cavity
        translate([casing_thickness, casing_thickness, casing_thickness]) {
            cube([buck_length, buck_width, buck_depth*2]);
            output_width = 3*wire_diameter;
            south_output_inset = (buck_width/2 - output_width/2);
            channel_rotation_angle = asin((south_output_inset - cable_inset_width)/wire_length_internal);
            extra_length = wire_diameter*sin(channel_rotation_angle);
            output_length = (cable_cavity_length - wire_length_internal*cos(channel_rotation_angle) + casing_thickness + extra_length);
            // Cable cavity (south)
            translate([buck_length, cable_inset_width, 0]) {
                rotate([0, 0, channel_rotation_angle]) cube([wire_length_internal, wire_diameter, buck_depth*2]);
                
            }
            // Cable cavity (north)
            translate([buck_length, buck_width - cable_inset_width - wire_diameter, 0]) {
                translate([-extra_length, 0, 0]) rotate([0, 0, -channel_rotation_angle]) cube([wire_length_internal, wire_diameter, buck_depth*2]);
            }
            // // Cable cavity (connecting channel)
            // translate([buck_length + wire_length_internal - wire_diameter, cable_inset_width + wire_diameter, 0]) {
            //     cube([wire_diameter, buck_width - 2*cable_inset_width - 2*wire_diameter, buck_depth*2]);
            // }
            // Cable cavity (output hole)
            translate([(buck_length + cable_cavity_length + casing_thickness) - output_length, buck_width/2 - output_width/2, 0]) {
                cube([output_length, output_width, buck_depth*2]);
            }
        }
    }
}


