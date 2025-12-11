#version 120

uniform float adsk_result_w, adsk_result_h, adsk_time;
vec2 res = vec2(adsk_result_w, adsk_result_h);
float time = adsk_time * 0.05;
uniform float contrast;

#define ITERATIONS 2
#define HASHSCALE1 .1031

// Real contrast adjustments by  Miles
float adjust_contrast(float col, float con)
{
float t = .18;
col = (1.0 - con) * t + con * col;

return col;
}

float hash12(vec2 p)
{
	vec3 p3  = fract(vec3(p.xyx) * HASHSCALE1);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

void main( void )
{
  vec2 uv = (gl_FragCoord.xy / res.xy);
  vec2 position = gl_FragCoord.xy;
  float a = 0.0;
  for (int t = 0; t < ITERATIONS; t++)
  {
      float v = float(t+1)*.152;
      vec2 pos = (position * v + time * 1500. + 50.0);
      a += hash12(pos);
  }
  float col = a / float(ITERATIONS);
  col = adjust_contrast(col, contrast +0.2);
  gl_FragColor = vec4(col);
}
