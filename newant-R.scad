// Parameters
$fn=50; // Amount of faces for circles
// face1
plane_x = 43.4;
plane_y = 44.8;
plane_z = 3.2;
plane_corner_radius = 5;
UHF_r = 9;
UHFs_r = 2;
screw_offset = 9.06;
face1_translate = [0, 0, -plane_z];

thickness_of_vertical = 2.2;//3.2;
depth_of_vertical = 31;
// faceR
faceR_x = thickness_of_vertical;
faceR_y = 34.8;
faceR_z = depth_of_vertical;
faceR_translate = [-faceR_x, 0, -faceR_z];
_rolling_x = -faceR_x;

// face3
face3_x = 51.6;
face3_y = thickness_of_vertical;
face3_z = depth_of_vertical;
face3_translate = [-faceR_x, -face3_y, -face3_z];

// face4
face4_rotation_z = 0;
face4_x = 20;
face4_y = thickness_of_vertical;
face4_z = depth_of_vertical;
face4_rotate = [0, 0, face4_rotation_z];
face4_translate = [face3_x-faceR_x+(face4_y*sin(face4_rotation_z)), -face4_y+0.125, -face4_z];

//face5
face5_rotation_z = -42.34;
face5_x = 10.9;
face5_y = thickness_of_vertical;
face5_z = depth_of_vertical;
face5_corr_calc_angle = 90+face5_rotation_z;
face5_x_correction = 0;//face5_y*cos(face5_corr_calc_angle);
face5_y_correction = 0;//face5_y*sin(face5_corr_calc_angle);
face5_rotate = [0, 0, face5_rotation_z];
face5_translate = [face3_x-faceR_x+(face4_y*sin(face4_rotation_z))+face4_x*cos(face4_rotation_z),
                    -face4_y+face4_x*sin(face4_rotation_z)+0.125,
                    -face5_z];

//face6
face6_rotation_z = 10.; //previous 16.1
face6_x = 64.8; //previous 83.3, but needed to be shortened by 25 mm on top or 20 mm on bottom, so shortened by 22.5 mm = 60.8 //but then added 1mm because that was too short
face6_y = thickness_of_vertical;
face6_z = depth_of_vertical;
face6_rotate = [0, 0, face6_rotation_z];
face6_translate = [face3_x-faceR_x+(face4_y*sin(face4_rotation_z))+face4_x*cos(face4_rotation_z)+face5_x*cos(face5_rotation_z),
                    -face4_y+face4_x*sin(face4_rotation_z)+0.125+face5_x*sin(face5_rotation_z),
                    -face5_z];

//face7
face7_x = 34;
face7_y = thickness_of_vertical;
face7_z = 112;
face7_x_offset = face6_x - (face7_x + 7);
face7_translate = [face7_x_offset, 0, (face6_z-face7_z)];

//face7-ex
face7_ex_dz_to_face6 = 30;
face7_ex_thickness = 6.5;

// hole SW
holeSW_r = 4.5;
holeSW_y = 20;
holeSW_lateral_padding = 9.45;///2.75 + 6.7;
holeSW_x_translate = face7_x-(holeSW_r+holeSW_lateral_padding);
holeSW_translate = [holeSW_x_translate, -holeSW_y/2, -(face6_z-face7_z-face5_z)-29.84];

// hole NW
holeNW_r = 4.5;
holeNW_y = 20;
holeNW_lateral_padding = holeSW_lateral_padding - 2.2;
holeNW_x_translate = face7_x-(holeNW_r+holeNW_lateral_padding);
holeNW_translate = [holeNW_x_translate, face7_y-holeNW_y/2, -(face6_z-face7_z-face5_z)-100.25];

//face8 22.5mm
face8_x = 22.5;
face8_y = thickness_of_vertical;
face8_z = depth_of_vertical;
face8_translate = [face7_x_offset+face7_x, face7_ex_thickness-thickness_of_vertical/2, (face6_z-face7_z)];


//face9 28mm

// Rounded corner cutter
module rounded_corner_cutter(r, z, side="SW") {
    if (side == "SW") {
        difference() {
            cube([r, r, z]);
            translate([r, r, 0]) cylinder(z, r, r);
        }
    } else if (side == "SE") {
        translate([r, 0, 0]) rotate([0, 0, 90]) difference() {
            cube([r, r, z]);
            translate([r, r, 0]) cylinder(z, r, r);
        }
    } else if (side == "NE") {
        translate([r, r, 0]) rotate([0, 0, -180]) difference() {
            cube([r, r, z]);
            translate([r, r, 0]) cylinder(z, r, r);
        }
    } else if (side == "NW") {
        translate([0, r, 0]) rotate([0, 0, -90]) difference() {
            cube([r, r, z]);
            translate([r, r, 0]) cylinder(z, r, r);
        }
    }
}


//face1
translate(face1_translate) difference() {
    //Plane
    cube([plane_x, plane_y, plane_z]);
    translate([0, plane_y-plane_corner_radius, 0]) rounded_corner_cutter(plane_corner_radius, plane_z, "NW");
    translate([plane_x-plane_corner_radius, plane_y-plane_corner_radius, 0]) rounded_corner_cutter(plane_corner_radius, plane_z, "NE");
    // UHF
    translate([plane_x/2, plane_y/2, 0]) cylinder(plane_z, UHF_r, UHF_r);
    //Screw NE
    translate([(plane_x/2)+screw_offset, (plane_y/2)+screw_offset, 0]) cylinder(plane_z, UHFs_r, UHFs_r);
    //Screw SE
    translate([(plane_x/2)+screw_offset, (plane_y/2)-screw_offset, 0]) cylinder(plane_z, UHFs_r, UHFs_r);
    //Screw SW
    translate([(plane_x/2)-screw_offset, (plane_y/2)-screw_offset, 0]) cylinder(plane_z, UHFs_r, UHFs_r);
    //Screw NW
    translate([(plane_x/2)-screw_offset, (plane_y/2)+screw_offset, 0]) cylinder(plane_z, UHFs_r, UHFs_r);
}

//faceR
translate(faceR_translate) cube([faceR_x, faceR_y, faceR_z]);

//face3
translate(face3_translate) cube([face3_x, face3_y, face3_z]);

//face4
translate(face4_translate) rotate(face4_rotate) cube([face4_x, face4_y, face4_z]);
// face4 joiner to face3
translate([face3_x-faceR_x, -face3_y, -face4_z]) difference() {
    cube([face4_y*sin(face4_rotation_z), face4_y, face4_z]);
    translate([face4_y*sin(face4_rotation_z)-.15, 0, 0]) rounded_corner_cutter(.15, face4_z, "SE");
}

//face5
translate(face5_translate) rotate(face5_rotate) cube([face5_x, face5_y, face5_z]);
// face5 joiner to face4
difference() {
    translate(face5_translate) cylinder(face5_z, face5_y, face5_y);
    translate(face4_translate) rotate(face4_rotate) translate([10, face4_y, 0])  cube([face4_x, face4_y, face4_z]);
    translate(face4_translate) rotate(face4_rotate) translate([0, -face4_y, 0])  cube([face4_x, face4_y, face4_z]);
    translate(face5_translate) rotate(face5_rotate) translate([0, -face5_y, 0]) cube([face5_x, face5_y, face5_z]);
}

//face6
translate(face6_translate) rotate(face6_rotate) {
    difference() {
        union() {
            cube([face6_x, face6_y, face6_z]);
            translate(face7_translate) cube([face7_x, face7_y, face7_z]);
            translate(face7_translate) cube([face7_x, face7_ex_thickness+thickness_of_vertical/2, (face7_z-face6_z-face7_ex_dz_to_face6)]);
            //face8
            //translate(face8_translate) cube([face8_x, face8_y, face8_z]);
        }
        translate(face7_translate) union() {
            //holeSW
            translate(holeSW_translate) rotate([-90, 0, 0]) cylinder(holeSW_y, holeSW_r, holeSW_r);
            //holeNW
            translate(holeNW_translate) rotate([-90, 0, 0]) cylinder(holeNW_y, holeNW_r, holeNW_r);
        }
    }
}
