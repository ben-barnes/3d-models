/* Notes:
 * 'width' refers to length in the x dimension.
 * 'depth' refers to length in the y dimension.
 * 'height' refers to length in the z dimension.
 */

$fn = 100;

/* Parameters */

mounting_hole_diameter = 3.5;
mounting_hole_x_spacing = 30;
mounting_hole_y_spacing = 16;
mounting_hole_inset = 4.75;
mounting_hole_thickness = 2;
mounting_nut_across_flats = 6.2;

spindle_circle_diameter = 19.5;
spindle_flat_to_radius = 18.5;
spindle_shelf_margin = 5;

clamp_profile_depth = 33;
clamp_profile_taper = 10;

clamp_jaw_width = 8;

clamp_hole_diameter = 3.5;
clamp_hole_spacing = 10;
clamp_hole_offset = 5;
clamp_bed_thickness = 5;
clamp_bolt_head_diameter = 6.5;

clamp_height = 20;
shelf_height = 10;

boss_height = 3.3;
boss_diameter = 17;
boss_centre_x = 21.5;
boss_centre_y = 12.5;

/* Derived values */

mounting_hole_centres = [
    [mounting_hole_inset, mounting_hole_inset],
    [mounting_hole_inset, mounting_hole_inset + mounting_hole_y_spacing],
    [mounting_hole_inset + mounting_hole_x_spacing, mounting_hole_inset]
];

mounting_tab_width = mounting_hole_x_spacing + 2 * mounting_hole_inset;
mounting_tab_depth = mounting_hole_y_spacing + 2 * mounting_hole_inset;

spindle_circle_radius = spindle_circle_diameter / 2;
spindle_flat_chord_depth = spindle_circle_diameter - spindle_flat_to_radius;

clamp_profile_width = mounting_tab_width;
clamp_profile_y = mounting_tab_depth;

/* Utilities */

function hexagon_flat_to_inscribed(across_flats) =
    2 * across_flats / sqrt(3) ;

/* Geometry */

// The rectangle that will mate with the gantry.
module MountingTab () {
    difference() {
        square([mounting_tab_width, mounting_tab_depth]);
        MountingHoles();
    }
}

// The mounting holes to be drilled in the mounting tab.
module MountingHoles() {
 for(centre = mounting_hole_centres) {
        translate(centre)
        circle(d = mounting_hole_diameter);
    }
}

module MountingNutRecesses() {
    nut_inscribed_diameter = hexagon_flat_to_inscribed(mounting_nut_across_flats);
    recess_depth = shelf_height - mounting_hole_thickness + 1;
    for(centre = mounting_hole_centres) {
        translate([centre.x, centre.y, -1])
        linear_extrude(recess_depth) {
            circle(d = nut_inscribed_diameter, $fn = 6);
        }
    }
}

// The trapezoid which forms the profile of the spindle clamp.
module ClampProfile() {
    clamp_profile_centre_x = clamp_profile_width / 2;
    clamp_profile_taper_inset = clamp_profile_depth * tan(clamp_profile_taper);
    
    spindle_profile_x = clamp_profile_centre_x;
    spindle_flat_y = spindle_circle_radius - spindle_flat_chord_depth;
    spindle_profile_y = spindle_flat_y + spindle_shelf_margin;
    
    clamp_jaw_depth = clamp_profile_depth - spindle_profile_y;
    clamp_jaw_x = clamp_profile_centre_x - clamp_jaw_width / 2;
    clamp_jaw_y = clamp_profile_depth - clamp_jaw_depth;
    
    difference() {
        polygon([
          [0, 0],
          [clamp_profile_taper_inset, clamp_profile_depth],
          [clamp_profile_width - clamp_profile_taper_inset, clamp_profile_depth],
          [clamp_profile_width, 0]
        ]);
        translate([spindle_profile_x, spindle_profile_y])
        SpindleProfile();
        translate([clamp_jaw_x, clamp_jaw_y])
        ClampJaw(clamp_jaw_depth + 1); // Extra depth here to avoid aliasing.
    }
}

// The rounded triangle cutout which mates with the spindle.
module SpindleProfile() {
    spindle_flat_chord_radius = spindle_circle_radius - spindle_flat_chord_depth;
    spindle_triangle_inscribed_radius = spindle_flat_chord_radius * 2;
    
    intersection() {
        rotate([0, 0, 90])
        circle(r = spindle_triangle_inscribed_radius, $fn = 3);
        circle(d = spindle_circle_diameter);
    }
}

module ClampJaw(depth) {
    square([clamp_jaw_width, depth]);
}

module ShelfCutout() {
    translate([-1, -1, shelf_height])
    linear_extrude(height = clamp_height - shelf_height + 1) {
        square([mounting_tab_width + 2, mounting_tab_depth + 1]);
    }
}
    
module ClampForm() {
    linear_extrude(height = clamp_height) {
        union() {
            MountingTab();
            translate([0, clamp_profile_y, 0])
            ClampProfile();
        }
    }
}

module ClampScrewHoles() {
    l = clamp_profile_width + 2;

    top_hole_z = clamp_hole_spacing + (clamp_height - clamp_hole_spacing) / 2;
    holes_y = mounting_tab_depth + clamp_profile_depth -clamp_hole_offset;
    
    nut_inscribed_diameter = hexagon_flat_to_inscribed(mounting_nut_across_flats);
    nut_recess_height = (l / 2) - (clamp_jaw_width / 2) - clamp_bed_thickness;
    
    for(x = [0, clamp_hole_spacing]) {
        rotate([0, 90, 0])
        translate([x - top_hole_z, holes_y, -1]) {
            cylinder(h = l, d = clamp_hole_diameter);
            cylinder(h = nut_recess_height, d = nut_inscribed_diameter, $fn = 6);
            translate([0, 0, l - nut_recess_height])
            cylinder(h = nut_recess_height, d = clamp_bolt_head_diameter);
        }
    }
}

module MountingTabBoss() {
    cylinder(h = shelf_height + boss_height, d = boss_diameter);
}

module Clamp() {
    union() {
        difference() {
            ClampForm();
            ShelfCutout();
            MountingNutRecesses();
            ClampScrewHoles();
        }
        translate([boss_centre_x + mounting_hole_inset, boss_centre_y])
        MountingTabBoss();
    }
}

Clamp();