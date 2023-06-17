
include <../BOSL/constants.scad>
use <../BOSL/threading.scad>

spool_diameter = 72;
spool_thickness = 62;
num_weights = 7; // [1,3,5,7,9]
label = "";

/* [Hidden] */
weight_diamater = 14.5;
weight_height = 55.5;
wall_thickness = 2;
cap_diameter_add = 15;
thread_diamater = spool_diameter - (2*wall_thickness);
thread_height = spool_thickness - weight_height - wall_thickness;

function circle_xy(radius,theta) = [radius*sin(theta),radius*cos(theta)];

module weight() {
    translate([0,0,weight_height/2])
    cylinder(d=weight_diamater,h=weight_height,$fn=360,center=true);    
}

module weights() {
    translate([0,0,wall_thickness]) {
        weight();

        radius = spool_diameter/4+weight_diamater/4;
        diff_angle = 360/(num_weights-1);
        for(slice=[1:num_weights-1]) {
            angle = diff_angle*slice;
            coord = circle_xy(radius,angle);
            translate([coord.x,coord.y,0]) weight();
        }
    }
}

module container() {
    difference() {
        cylinder(d=spool_diameter,h=spool_thickness,$fn=360,center=true);

        translate([0,0,weight_height/2+spool_thickness/2])
        cylinder(d=spool_diameter-wall_thickness,h=spool_thickness,$fn=360,center=true);
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
        cylinder(d=spool_diameter,h=spool_thickness,$fn=360,center=false);

        translate([0,0,(wall_thickness+weight_height)])
        cylinder(d=spool_diameter-wall_thickness,h=spool_thickness,$fn=360,center=false);

        weights();
    }

    translate([0,0,weight_height+2*wall_thickness])
    intersection() {
        cylinder(d=spool_diameter-wall_thickness,h=thread_height,$fn=360,center=true);
        threaded_nut(od=thread_diamater+5,id=thread_diamater,h=thread_height,pitch=1.25,left_handed=false,slop=0.2,$fa=1,$fs=1);
    }

    rotate([180,0,0])
    endcap();
}

module cap() {
    difference()
    {
        translate([0,0,thread_height/2])
        intersection(){
            cylinder(d=spool_diameter,h=thread_height,$fn=360,center=true);
            threaded_rod(d=thread_diamater-.4, l=thread_height, pitch=1.25, left_handed=false, $fa=1, $fs=1);
        }

        translate([0,0,wall_thickness+.5*thread_height])
        cylinder(d=thread_diamater-4,h=thread_height+5,$fn=360);
    }

    rotate([180,0,0])
    endcap();
}

body();

translate([95,0,0]) cap();