
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

/* [Hidden] */
wall_thickness = 2;
cap_diameter_add = 15;
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
    grip_diameter = 5;
    cap_diameter = spool_diameter+cap_diameter_add-grip_diameter/2;
    cylinder(d=cap_diameter, h=wall_thickness, $fn=360);    
    cap_edging(50,cap_diameter/2,grip_diameter);

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

body();

translate([95,0,0]) cap();