#version 3.7;

#include "colors.inc"
#include "metals.inc"
#include "woods.inc"

#declare MyCyan    = rgbf <0, 1, 1, 0>;

global_settings {
    assumed_gamma 1.0
}

camera {
   location <-5, 1, -30>
   angle 45 // direction <0, 0,  1.7>
   right x*image_width/image_height
   look_at <0,0,0>
}

#declare Dist=80.0;
light_source {< -50, 25, -50> color White
     fade_distance Dist fade_power 2
//   area_light <-40, 0, -40>, <40, 0, 40>, 3, 3
//   adaptive 1
//   jitter
}

#declare T0 = texture { F_MetalC }

#declare T =
texture {
    pigment {
        color Cyan
    }
    finish {
        specular 1.00
        roughness 0.1
        ambient 0.25
        reflection 0.65
    }
}

#declare Floor_Texture =
    texture { pigment { P_WoodGrain18A color_map { M_Wood18A }}}
    texture { pigment { P_WoodGrain12A color_map { M_Wood18B }}}
    texture {
        pigment { P_WoodGrain12B color_map { M_Wood18B }}
        finish { reflection 0.25 }
    }


plane { y,-10
    texture { Floor_Texture
        scale 0.5
        rotate y*90
        rotate <10, 0, 15>
        translate z*4
    }
}

box {
    <-2.50, 0, -1.75>, <2.50, 3.75, 1.75> 
    texture { T }
}

cone {
    <-1.0, -3, -0.75>, .333, <1.0, -3, 0.75>, 1
    texture { T }
}

sphere {
    <-1.1, -3, -0.75>, .4
    texture { T }
    pigment { White }
}

text {
    internal 1 "D" 1 , 0
    translate < -2.2, 2 - mod(frame_number,2)/5, -1.77>
}

text {
    internal 1 "Q" 1 , 0
    translate < 1.5, 1.8 + mod(frame_number,2)/5, -1.77>
}

#declare LBox =
    union {
        box {
            <-1.3,1.3,-0.25>, <1.3,0,0.25>
        }
        box {
            <0, 1.3, -0.25>, < 1.3, -1.3, 0.25>
        }
    }

#declare QuarterTorii =
    difference {
        torus {
            1, .2
            rotate x*90
        }
        LBox
        texture { T }
        pigment { Black }
    }

#declare DQTube =
union {
    cylinder {
        < -3.0, -3.0, -0.75>, < -1.1, -3.0, -0.75> .2
        texture { T }
        pigment { Black }
    }
    
    cylinder {
        < -4.02, -2.0, -0.75>, < -4.02, 1.0, -0.75> .2
        texture { T }
        pigment { Black }
    }
    
    cylinder {
        < -3.02, 2.0, -0.75>, < -2.5, 2.0, -0.75>, 0.2
        texture { T }
        pigment { Black }
    }
    object { QuarterTorii
        translate <-3.0, -2, -0.75>
    }
    object { QuarterTorii
        rotate x*180
        translate <-3.0, 1.0, -0.75>
    }
}

DQTube
object {
    DQTube
    rotate y*180
}

object {
    QuarterTorii
    rotate y*180
    translate < -1.0, 0.0, 0.75>
}
cylinder {
    < -1.0, -1.0, 0.75>, < -5.0, -1.0, 0.75> , 0.2
    texture { T }
    pigment { Black }
}


#declare DQWave =
union {
    cylinder {
        < 0, 0, 0> <1,0,0>, .1
        pigment { Red }
    }
    cylinder {
        < 1, 0, 0> <1,1,0>, .1
        pigment { Red }
    }
    cylinder {
        < 1, 1, 0> <2,1,0>, .1
        pigment { Red }
    }
    cylinder {
        < 2, 1, 0> <2,0,0>, .1
        pigment { Red }
    }
}

#declare DQWave4 =
union {
    object {
        DQWave
        translate <-10,6,0.75>
    }
    object {
        DQWave
        translate <-8,6,0.75>
    }
    object {
        DQWave
        translate <-6,6,0.75>
    }
    object {
        DQWave
        translate <-4,6,0.75>
    }
    
    object {
        DQWave
        translate <-2,6,0.75>
    }
}

#declare DQWave2 =
union {
    object {
        DQWave
        translate < 2.5, -6, 0.75>
        scale x*2
    }
    object {
        DQWave
        translate < 4.5, -6, 0.75>
        scale x*2
    }
    object {
        DQWave
        translate < 6.5, -6, 0.75>
        scale x*2
    }
}

object {
    DQWave4
    translate < -frame_number / 32 * 2, 0, 0>
    bounded_by { box { <-8,8,0.70>, <-2,2,0.80> }}
}

object {
    DQWave2
    translate < -frame_number / 32 * 2, 0, 0>
    bounded_by { box { <4.5,-8,0.70>, <8.5,-2,0.80> }}
}

#if (mod(frame_number,2)=1)
    cone {
        < -0.25, 0, -2.0>, 0.5, < -.25, 0.7, -2.0>, 0.05
        pigment { White }
    }                      
#else
    cone {
        < -0.25, 0, -2.0>, 0.5, < -.25, 0.7, -2.0>, 0.05
        pigment { Red }
    }                      
#end

