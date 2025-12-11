#version 120

uniform sampler2D front, adsk_results_pass2;
uniform float adsk_result_w, adsk_result_h, adsk_front_w, adsk_front_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
uniform float vhs_res;

void main( void )
{
  vec2 p = (gl_FragCoord.xy / res.xy ) * vhs_res;
  vec4 col = texture2D( adsk_results_pass2, p );
  gl_FragColor = vec4(col.rgb,1.0 );
}
