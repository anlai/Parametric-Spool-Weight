
include <./BOSL/constants.scad>
use <./BOSL/threading.scad>

// diameter of inside of the spool
spool_diameter = 72;

// thickness of the inside of the spool
spool_thickness = 62;

// # of weight cavities, created with a center and weights circling
num_weights = 7; // [1,3,5,7,9]

// label to embed on the end caps
label = "";

// diameter of the weight(s)
weight_diameter = 14.5;

// height of the weight(s)
weight_height = 50.5;

// number circles on cap edge
cap_edge_grip_num = 50;

// size of cirlces on cap edges
cap_edge_grip_diameter = 15;

// include recessed finger grip
cap_finger_grip = true;

// scaling factor based on cap diameter
cap_handle_depth_factor = .1; // [.1:0.1:.5]

// scaling factor based on cap diameter
cap_handle_size_factor = .75; // [.5:.05:1]

module __Customizer_Limit__ () {}

/* [Hidden] */
wall_thickness = 2;
cap_diameter_add = 15;
cap_grip_diameter = 25;
cap_diameter = spool_diameter+cap_diameter_add-cap_grip_diameter/2;
thread_diamater = spool_diameter - (2*wall_thickness);
// from the edge of container to edge of weights
// when weights are centered in the container
weight_height_offset = (spool_thickness-weight_height)/2;

function circle_xy(radius,theta) = [radius*sin(theta),radius*cos(theta)];

module weight() {
    translate([0,0,weight_height/2])
    cylinder(d=weight_diameter,h=weight_height,$fn=360,center=true);    
}

module weights() {
    translate([0,0,weight_height_offset]) {
        weight();

        radius = spool_diameter/4+weight_diameter/4;
        diff_angle = 360/(num_weights-1);
        for(slice=[1:num_weights-1]) {
            angle = diff_angle*slice;
            coord = circle_xy(radius,angle);
            translate([coord.x,coord.y,0]) weight();
        }
    }
}

module endcap() {
    cylinder(d=cap_diameter, h=wall_thickness, $fn=360);    
    cap_edging(cap_edge_grip_num,cap_diameter/2,cap_edge_grip_diameter);

    color("black")
    translate([0,0,wall_thickness])
    linear_extrude(.01)
    text(text=label,font="Arial,style=bold",halign="center",valign="center");
}

module cap_edging(num_circles,circle_radius,grip_diameter) {
    diff_angle = 360/num_circles;
    for(slice=[1:num_circles]) {
        angle = diff_angle*slice;
        coord = circle_xy(circle_radius,angle);
        
        translate([coord.x,coord.y,0]) cylinder(d=grip_diameter,h=wall_thickness,$fn=360);
    }
}

module body() {
    // body + inner thread
    difference() {
        // outer body
        cylinder(d=spool_diameter,h=spool_thickness,$fn=360,center=false);

        // top cavity for the threads
        translate([0,0,weight_height_offset+weight_height])
        cylinder(d=spool_diameter-wall_thickness,h=weight_height_offset,$fn=360,center=false);

        weights();
    }

    // threads
    // note: threads are centered on the z-axis, so it has to be raised an additional half the offset
    translate([0,0,weight_height_offset+weight_height+weight_height_offset/2])
    intersection() {
        cylinder(d=spool_diameter-wall_thickness,h=weight_height_offset,$fn=360,center=true);
        threaded_nut(od=thread_diamater+5,id=thread_diamater,h=weight_height_offset,pitch=1.25,left_handed=false,slop=0.2,$fa=1,$fs=1);
    }

    // end cap, top aligns with z = 0
    rotate([180,0,0])
    endcap();
}

module cap() {
    difference() {
        // the outer threads
        translate([0,0,weight_height_offset/2])
        intersection(){
            cylinder(d=spool_diameter,h=weight_height_offset,$fn=360,center=true);
            threaded_rod(d=thread_diamater-.4, l=weight_height_offset, pitch=1.25, left_handed=false, $fa=1, $fs=1);
        }

        // carve out the center of the cap
        translate([0,0,wall_thickness])
        cylinder(d=thread_diamater-2*wall_thickness,h=weight_height_offset,$fn=360);        
    }

    rotate([180,0,0])
    endcap();
}

module finger_grip() {
    difference() {
        vertical_scale=.1;
        scale([.75,.75,vertical_scale])
        sphere(d=cap_diameter,$fn=360);

        translate([0,0,-(cap_diameter*vertical_scale)/4])
        cube([cap_diameter, cap_diameter, (cap_diameter*vertical_scale)/2],center=true);
        
        cube([cap_diameter, cap_diameter/3, cap_diameter],center=true);
    }
}


body();

translate([cap_diameter+8+cap_edge_grip_diameter,0,0])
difference() {
    cap();

    if (cap_finger_grip) {
        translate([0,0,-wall_thickness])
        finger_grip();
    }
}

