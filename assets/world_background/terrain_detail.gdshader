shader_type canvas_item;
render_mode unshaded;
uniform sampler2D grass_detail : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D water_detail : source_color, repeat_enable, filter_linear_mipmap;
uniform int island_season=1;
uniform vec2 world_size=vec2(4320.0,7680.0);
void fragment(){
 vec4 base=texture(TEXTURE,UV);
 vec2 local=UV*world_size/480.0;
 float ground=smoothstep(0.06,0.08,UV.y);
 float green=smoothstep(0.08,0.18,base.g-max(base.r,base.b))*ground;
 float saturation=(max(max(base.r,base.g),base.b)-min(min(base.r,base.g),base.b))/max(max(max(base.r,base.g),base.b),0.01);
 float gold=smoothstep(0.56,0.72,saturation)*smoothstep(0.12,0.28,base.r-base.b)*smoothstep(0.12,0.30,base.g-base.b)*step(0.50,UV.y)*(1.0-step(0.52,UV.x))*(1.0-green);
 float snow=smoothstep(0.55,0.75,min(base.r,base.g))*smoothstep(0.0,0.07,base.b-base.r)*step(0.5,UV.y);
 float water=smoothstep(0.10,0.30,base.b-base.r)*smoothstep(0.08,0.22,base.g-base.r)*ground*(1.0-smoothstep(0.25,0.42,base.r));
 vec3 plain_grass=texture(grass_detail,local).rgb;
 float fine=dot(plain_grass,vec3(0.299,0.587,0.114));
 vec3 color=base.rgb;
 vec3 meadow=plain_grass;
 if(island_season==1){meadow*=vec3(1.04,0.99,0.88);}
 if(island_season==2){meadow=vec3(0.94,0.70,0.20)*(0.94+(fine-0.60)*0.20);}
 if(island_season==3){meadow=vec3(0.88,0.94,1.0)*(0.98+(fine-0.60)*0.08);}
 color=mix(color,meadow,green*0.98);
 vec2 ripple=vec2(sin(UV.y*105.0+TIME*2.4),cos(UV.x*125.0-TIME*2.0))*0.0012;
 color=mix(color,texture(TEXTURE,UV+ripple).rgb,water*0.38);
 vec3 flow=texture(water_detail,local*1.4+vec2(TIME*0.018,-TIME*0.048)).rgb;
 float shimmer=sin(local.x*18.0+local.y*30.0-TIME*1.8)*0.025;
 color=mix(color,color*(0.88+dot(flow,vec3(0.299,0.587,0.114))*0.28)+shimmer,water*0.72);
 // White waterfall ribbons need their own flow, beyond the cyan river mask.
 vec2 upper=abs((UV-vec2(0.85,0.157))/vec2(0.036,0.030));
 vec2 lower=abs((UV-vec2(0.889,0.861))/vec2(0.034,0.025));
 float face=max(1.0-smoothstep(0.7,1.0,max(upper.x,upper.y)),1.0-smoothstep(0.7,1.0,max(lower.x,lower.y)));
 float aquatic=smoothstep(0.01,0.12,base.b-base.r)+smoothstep(0.78,0.96,min(base.r,base.g));
 float ribbons=pow(max(0.0,sin(UV.x*2900.0+sin(UV.y*85.0)*0.7)),5.0);
 float descent=sin(UV.y*640.0-TIME*15.0)*0.5+0.5;
 color+=vec3(0.14,0.19,0.22)*face*clamp(aquatic,0.0,1.0)*ribbons*descent;
 COLOR=vec4(clamp(color,vec3(0.0),vec3(1.0)),base.a);
}
