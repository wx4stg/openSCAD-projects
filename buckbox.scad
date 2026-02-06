// Buck converter housing for TTU lightning's WT-SANTA instrument
// Created 5 Februrary 2026 by Sam Gardner <samuel.gardner@ttu.edu>

// Parameters (all dimensions in mm)
buck_length = 45;
buck_depth = 15;
lid_depth = 5;
buck_width = 22;
casing_thickness = 2;

cable_cavity_length = 20;
cable_inset_width = 0.4;
wire_length_internal = 15;
wire_diameter = 3.4;

lid_tolerance = 0.2;
tab_length = 3;

lock_sphere_diameter = 3;
lock_sphere_inset = 2.5;

MAKE_CASE = true;
MAKE_LID = true;

$fn = 30;

// Derived parameters
buck_length_actual = buck_length + 2*cable_cavity_length;
lid_width = buck_width + 2*casing_thickness;

output_width = 2.5*wire_diameter;
south_output_inset = (buck_width/2 - output_width/2);
channel_rotation_angle = asin((south_output_inset - cable_inset_width)/wire_length_internal);
extra_length = wire_diameter*sin(channel_rotation_angle);
output_length = (cable_cavity_length - wire_length_internal*cos(channel_rotation_angle) + casing_thickness + extra_length);

if (MAKE_CASE) {
    // Bottom half
    difference() {
        // Outer shell
        cube([buck_length_actual + 2*casing_thickness, buck_width + 2*casing_thickness, buck_depth + casing_thickness]);
        translate([casing_thickness, casing_thickness, casing_thickness]) union() {
            // Inner cavity
            translate([cable_cavity_length, 0, 0]) {
                cube([buck_length, buck_width, buck_depth*2]);
                // Cable cavity (south east)
                translate([buck_length, cable_inset_width, 0]) {
                    rotate([0, 0, channel_rotation_angle]) cube([wire_length_internal, wire_diameter, buck_depth*2]);
                    
                }
                // Cable cavity (north east)
                translate([buck_length, buck_width - cable_inset_width - wire_diameter, 0]) {
                    translate([-extra_length, 0, 0]) rotate([0, 0, -channel_rotation_angle]) cube([wire_length_internal, wire_diameter, buck_depth*2]);
                }
                // Cable cavity (east output hole)
                translate([(buck_length + cable_cavity_length + casing_thickness) - output_length, buck_width/2 - output_width/2, 0]) {
                    cube([output_length, output_width, buck_depth*2]);
                }
            }
            // Cable cavity (west output hole)
            translate([-casing_thickness, buck_width/2 - output_width/2, 0]) {
                cube([output_length, output_width, buck_depth*2]);
            }
            // Cable cavity (south west)
            translate([output_length-(extra_length+casing_thickness), south_output_inset, 0]) {
                rotate([0, 0, -channel_rotation_angle]) cube([wire_length_internal, wire_diameter, buck_depth*2]);
            }
            // Cable cavity (north west)
            translate([output_length-casing_thickness, buck_width - south_output_inset - wire_diameter, 0]) {
                rotate([0, 0, channel_rotation_angle]) cube([wire_length_internal, wire_diameter, buck_depth*2]);
            }
            translate([0, -casing_thickness, -casing_thickness+(buck_depth+2*casing_thickness-lid_depth)]) union() {
                // Lock spheres
                translate([lock_sphere_inset, 0, 0]) sphere(lock_sphere_diameter/2);
                translate([((buck_length + 2*cable_cavity_length) - lock_sphere_inset), 0, 0]) sphere(lock_sphere_diameter/2);
                translate([lock_sphere_inset, (buck_width + 2*casing_thickness), 0]) sphere(lock_sphere_diameter/2);
                translate([((buck_length + 2*cable_cavity_length) - lock_sphere_inset), (buck_width + 2*casing_thickness), 0]) sphere(lock_sphere_diameter/2);
            }
        }
    }
}




if (MAKE_LID) {
    // Lock spheres
    translate([casing_thickness, 0, (buck_depth - lid_depth + 2*casing_thickness)]) {
        translate([lock_sphere_inset, 0, 0]) sphere(lock_sphere_diameter/2);
        translate([((buck_length + 2*cable_cavity_length) - lock_sphere_inset), 0, 0]) sphere(lock_sphere_diameter/2);
        translate([lock_sphere_inset, (buck_width + 2*casing_thickness), 0]) sphere(lock_sphere_diameter/2);
        translate([((buck_length + 2*cable_cavity_length) - lock_sphere_inset), (buck_width + 2*casing_thickness), 0]) sphere(lock_sphere_diameter/2);
    }
    // Lid tabs
    translate([0, (buck_width + 2*casing_thickness - (2/3)*buck_width)/2, (buck_depth - lid_depth + 2*casing_thickness)]) {
        translate([-(casing_thickness+tab_length), 0, 0]) cube([tab_length, (2/3)*buck_width, lid_depth/2]);
        translate([(casing_thickness+tab_length+buck_length_actual), 0, 0]) cube([tab_length, (2/3)*buck_width, lid_depth/2]);
    }
    // Lid
    difference() {
        // Outer shell
        translate([-casing_thickness, -casing_thickness, buck_depth-lid_depth]) {
            cube([(buck_length_actual + 4*casing_thickness), (lid_width + 2*casing_thickness), lid_depth+2*casing_thickness]);
        }
        // Inner cavity
        translate([-lid_tolerance, -lid_tolerance, lid_tolerance]) {
            cube([buck_length_actual + 2*casing_thickness + 2*lid_tolerance, buck_width + 2*casing_thickness + 2*lid_tolerance, buck_depth + casing_thickness]);
        }
    }
}