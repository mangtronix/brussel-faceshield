/*
    FILE   : anti_projection.scad
    AUTHOR : Nicolas H.-P. De Coster (Vigon) <ndcoster@meteo.be>
             Additions by Michael Ang / Mangtronix <contactmang@gmail.com>
    DATE   : 2020-03-28
    LICENSE : M.I.T. (https://opensource.org/licenses/MIT)
    VERSION: 3.2 (European 4 hole punch, 1x without support) [2020-03-27 14:00 UTC]
    NOTES  :
        - 3.2 (mangtronix):
                When using 4 pins the spacing is set to European "888" 4 hole punch
                Pin shape is loaded from STL, does not require supports
                Holes in band are not made by default (set make_holes_in_band = 1) to make holes in the inner band
                Fixed small solid area between headbands when stacking 
                Can move round pin to build plate when printing single headband, so no supports needed (fix_is_centered=0)
        - 3.1 : (printing) layer height as main parameter for stacked distance and piece height automatic rounding (better slicing/printing results with thick layers)
        - 3.0 : 2020-03-25 : automatic calculation no matter the number of pins, placing them properly on circle or temple depending on fix_dist parameter
        - 2.3 : corrected bug : proper hook support
        - 2.1 : corrected bug : no more parity issue with dash line
        - 2.0 : stackable version, automatically calculated dashet support
        - 1.1 : lowered pins (limiting support)
        - 1.0 : added central pin (was avoided previously because more complex punch in transaprent foil but asked explicitely by St Pierre Hospital, thus added)
        - 0.2 : adapted pins size and position
        - 0.1 : second draft : added pins for foil clipping
        - 0.0 : first draft : clipping system
//*/

//General params
n_stacked = 1;    //vertical repeat
layer_h   = 0.35;  //printing layer height : will be used to adjust sizes so that they remain exact integer multiples of the layer height value. Piece height ([height]) and distance between stacked pieces ([stacked_d]) are the rounding targeted values.
stacked_d = 2*layer_h;  //distance between stacked pieces (better use integer multiple of your layer height)
e=0.01;           //general purpose "epsilon value" for better preview rendering (avoid artifacts)


//Dashes (support for stacking)
dash_l    = .8;   //dash length
dash_int  = 6;    //dash interval

//Main parameters
out_d     = 115;  //inside diameter of outer ring
in_d      = 95;   //inside diameter of inner ring
approx_h  = 8;    //height of the module (approximative, will be adjusted to be an integer multiple value of layer_h)
sec       = 5;    //setback from joining branches
th        = 1.2;  //thickness of module (=0.4*3 or 0.6*2 for printing speed optimization)
hook_d    = 4;    //hooks diameter


//Fixing pins
fix_n    = 4;     //number of pins
fix_dist_single_punch = 297 - 2*10; // (12 seems to be the standard distance from edge on a paper punch but 10 measured on mine)
fix_dist_4hole = 297 - (297 - 3 * 80); // 4 hole punch holes are centered on long edge with 3x 80mm spacing between the 4 holes

// Increase the spacing between the pins, to tension the sheet. E.g. with fix_tension = 4 there is an extra 4mm between the furthest pins
fix_tension = 0; 

fix_dist = fix_distance(fix_n); // Choose the fixing distance based on the number of pins

fix_d = 3;
fix_h = 3.5;

//(diameter 6 is supposed to be the standard https://en.wikipedia.org/wiki/Hole_punch) but we observer 5 often (3+2*1.2 = 5.4 that allows tight fitting)
fix_over = 1.2;


// Pins can be centered in headband (1) or set towards bottom of band (0) which allows printing without supports
fix_is_centered = 1;

// Load the pin shape from STL or use generated round pin
fix_use_stl = 1;

// STL file to use for pin
fix_stl = "pin_for_6mm_hole.stl";

// Make holes in band (1) or keep inner band solid (0)
make_holes_in_band = 0;

height = round(approx_h/layer_h)*layer_h;
echo("Height : ", height);
out_r = out_d/2;
in_r  = in_d/2;
hook_r = hook_d/2;
holes_d = height/2;
fix_r = fix_d/2;

for(i=[0:n_stacked-1]){
    
translate([0,0,i*(height+stacked_d)])
    
difference() {
    union(){

      structure(out_d, in_d, hook_d, height, th);

      arc_l = PI*(out_d+2*th)*3/4;
        
      fix_int = fix_dist/(fix_n-1);

      mid_pos = (fix_n-1)/2;
      alpha_int = 360*fix_int/(PI*(out_d+2*th));
      /*
      // Fixings
      */
      
      for(p = [0:fix_n-1]){
          pos_n = p-mid_pos;
          alpha = pos_n * alpha_int;
          if(alpha < -135){
            translate([(fix_dist-arc_l)/2,0,0])
            rotate([0,0,-135])
              translate([0,0,fix_center_height()])
              rotate([-90,0,135])
              translate([0, 0, out_r ])
                fixing();
                //fixing(d=fix_d, h=fix_h+th, over=fix_over);
                //translate([0, 0, th - 0.2]) fixing_stl();
          }
          else if(alpha > 135){
            translate([0,(fix_dist-arc_l)/2,0])
            rotate([0,0,135])
              translate([0,0,fix_center_height()])
              rotate([-90,0,135])
              translate([0, 0, out_r ])
                fixing();
                //fixing(d=fix_d, h=fix_h+th, over=fix_over);
                //translate([0, 0, th - 0.2]) fixing_stl();
          }
          else{
            rotate([0,0,alpha])
              translate([0,0,fix_center_height()])
              rotate([-90,0,135])
              translate([0, 0, out_r ])
                fixing();
                //fixing(d=fix_d, h=fix_h+th, over=fix_over);
                //translate([0, 0, th - 0.2]) fixing_stl();
          }

      }
    /*
      %translate([out_r+th, (fix_dist-arc_l)/2,height/2])
        rotate([0,90,0])
          fixing(d=fix_d, h=fix_h, over=fix_over);
      %translate([(fix_dist-arc_l)/2,out_r+th,height/2])
        rotate([-90,0,0])
          fixing(d=fix_d, h=fix_h, over=fix_over);  
      */

        

    }
    
    // The bottom of the pins may be below the print surface
    // Trim any material below z=0
    trim_height = 20;
    translate([0,0,-trim_height])
        cylinder(h = trim_height, r = 100);
}

//support
if(i != n_stacked-1){
  translate([0,0,i*(height+stacked_d)+height])
    structure(out_d, in_d, hook_d, stacked_d, th, isStruct=true);

}
}

/*////////////////
// M O D U L E S 
*/////////////////
module empty_cyl(in_d, th, h, dashed=false){
  difference(){
    cylinder(d=in_d+2*th, h=h);
    translate([0,0,-e])cylinder(d=in_d, h=h+2*e);
    if(dashed){
        circ = PI*(in_d+th/2);
        n_cube_dash = ceil(circ/dash_int);
        alpha = 360/n_cube_dash;
        for(i=[0:n_cube_dash-1]){
            rotate([0,0,i*alpha+30]) //+30 cheating to get proper hooks support (dirty but works)
            translate([in_d/2+th,0,h/2])
              cube([in_d/2+th+e, dash_int-dash_l, h+2*e], center=true);
        }
    }
  }
}

module temple(l,w,h,dashed=false){
  difference(){
    cube([l,w,h]);
    if(dashed){
      n_dash = ceil(l/dash_int);
      for(i=[0:n_dash]){
        translate([dash_l+dash_int*i,-e,-e])cube([dash_int-dash_l, w+2*e, h+2*e]);
      }
    }
  }
}

module arc3_4(in_d, th, h, dashed=false){
  difference(){
    empty_cyl(in_d, th, h, dashed=dashed);
    translate([0,0,-e])cube([in_d, in_d, h+2*e]);
  }
}

module clip(h,w,th,clip_solid){

  difference(){
    cube([w,h,clip_solid]);
    translate([th,th,-e/2])cube([th,h-2*th, clip_solid+e]);
    translate([w-2*th,th,-e/2])cube([th,h-2*th, clip_solid+e]);
    translate([th,h-2*th,-e/2])cube([w-2*th,th, clip_solid+e]);
    translate([3*th,2*th,-e/2])cube([th, h-5*th, clip_solid+e]);
    translate([3*th,th,-e/2])cube([w-6*th, th, clip_solid+e]);
    translate([3*th,2*th+(h-8*th)/3,-e/2])cube([w-6*th, th, clip_solid+e]);
    translate([3*th,2*th+2*((h-8*th)/3)+th,-e/2])cube([w-6*th, th, clip_solid+e]);
    translate([3*th,h-4*th,-e/2])cube([w-6*th, th, clip_solid+e]);
  }
    
}

module fixing(){
    if (fix_use_stl) {
        translate([0, 0, th - 0.2]) // Make sure pin attaches fully to curved band
            import(fix_stl);
    } else {
        // Generated round pin
        fixing_round(d=fix_d, h=fix_h+th, over=fix_over);
    }
}
        


module fixing_round(d, h, over){
    sph_d = d+2*over;
    cylinder(d=d, h=h-d/2, $fn=50);
    translate([0,0,h-d/2])difference(){
      sphere(d=sph_d, $fn=50);
    translate([0,0,-sph_d/2])cube([sph_d,sph_d,sph_d], center=true);
    }
}

module structure(out_d, in_d, hook_d, height, th, isStruct=false){
    out_r = out_d/2;
    in_r = in_d/2;
    hook_r = hook_d/2;
    arc_dist = 3*PI*in_d/4;
    n_holes = floor(arc_dist/height);
    
/*
// Arcs
*/
translate()arc3_4(out_d, th, height, dashed=isStruct,$fn=100);
difference(){
  translate([out_r-in_r, out_r-in_r, 0])arc3_4(in_d, th, height, dashed=isStruct, $fn=100);
  if(!isStruct){
    if (make_holes_in_band) {
        for(i=[1:n_holes+1]){
          translate([out_r-in_r, out_r-in_r, holes_d])
          rotate([90,0,90-i*270/(n_holes+2)])
            cylinder(d=holes_d, h=in_d+th+e, $fn=6);
        }
    }
  }

}

/*
// Temples
*/
translate([0, out_r, 0])
  temple(out_r+th-sec, th, height, dashed=isStruct);
translate([out_r+th, 0, 0])
  rotate([0,0,90])
  temple(out_r+th-sec, th, height, dashed=isStruct);

/*
// Hooks
*/
translate([hook_r+out_r+th,out_r-sec,0])
  rotate([0,0,180])
    arc3_4(hook_d, th, height, dashed=isStruct, $fn=100);
translate([out_r-sec, hook_r+out_r+th,0])
  rotate([0,0,180])
    arc3_4(hook_d, th, height, dashed=isStruct,$fn=100);

arc_l = PI*(out_d+2*th)*3/4;
}


//// Functions
// Choose the fixing distance based on the number of pins
// $$$ could instead have presets that return the pin locations directly
function fix_distance(fix_count) = (fix_count == 4) ? fix_dist_4hole + fix_tension : fix_dist_single_punch + fix_tension;

// Pins can either be centered on the headband or offset so that they don't need supports when printing
function fix_center_height() = (fix_is_centered == 1) ? height/2 : fix_d - 2 * layer_h;