#version 120
// based on https://www.shadertoy.com/view/MdffD7 by FMS_Cat
uniform float adsk_result_w, adsk_result_h, adsk_time, adsk_front_w, adsk_front_h;
vec2 res = vec2(adsk_result_w, adsk_result_h);
uniform sampler2D front, adsk_results_pass1;
uniform float vhs_res;
uniform float color_bleeding;
uniform float tape_wave;
uniform float tape_crease;
uniform float switching_color;
uniform float ac_beat;
uniform float yiq_blend;
uniform vec3 yiq_offset;
uniform vec3 bleed_offset;
uniform bool enable_tint, enable_bleed;
uniform float speed, offset;

#define V vec2(0.,1.)
#define PI 3.14159265
#define HUGE 1E9
#define saturate(i) clamp(i,0.,1.)
#define lofi(i,d) floor(i/d)*d
#define validuv(v) (abs(v.x-0.5)<0.5&&abs(v.y-0.5)<0.5)

float time = adsk_time * 0.05 * speed + offset;
vec2 VHSRES = vec2(adsk_front_w * vhs_res, adsk_front_h * vhs_res);

float v2random(vec2 uv) {
  return texture2D(adsk_results_pass1, mod(uv, vec2(1.0))).x;
  // return 0.5;
}

vec3 vhsTex2D(vec2 uv) {
  if(validuv(uv)) {
    return texture2D(front, uv).xyz;
  }
  return vec3(0.1, 0.1, 0.1);
}

vec3 rgb2yiq(vec3 rgb) {
  return mat3(0.299, 0.596, 0.211, 0.587, -0.274, -0.523, 0.114, -0.322, 0.312) * rgb;
}

vec3 yiq2rgb(vec3 yiq) {
  return mat3(1.000, 1.000, 1.000, 0.956, -0.272, -1.106, 0.621, -0.647, 1.703) * yiq;
}

void main(void) {
  vec2 uv = (gl_FragCoord.xy / VHSRES.xy);
  vec2 uvn = uv;
  vec3 col = vec3(0.0);
  // tape wave
  uvn.x += (v2random(vec2(uvn.y / 10.0, time / 10.0) / 1.0) - 0.5) / VHSRES.x * tape_wave;
  uvn.x += (v2random(vec2(uvn.y, time * 10.0)) - 0.5) / VHSRES.x * tape_wave;
  // tape crease
  float tcPhase = smoothstep(0.9, 0.96, sin(uvn.y * 8.0 - (time + 0.14 * v2random(time * vec2(0.67, 0.59))) * PI * 1.2));
  float tcNoise = smoothstep(0.3, 1.0, v2random(vec2(uvn.y * 4.77, time)));
  float tc = tcPhase * tcNoise;
  uvn.x = uvn.x - tc / VHSRES.x * 8.0 * tape_crease;
  // switching noise
  float snPhase = smoothstep(6.0 / VHSRES.y, 0.0, uvn.y);
  uvn.y += snPhase * 0.3;
  uvn.x += snPhase * ((v2random(vec2(uv.y * 100.0, time * 10.0)) - 0.5) / VHSRES.x * 24.0);
  // fetch
  col = vhsTex2D(uvn);
  // crease noise
  float cn = tcNoise * (0.3 + 0.7 * tcPhase);
  if(0.29 < cn) {
    vec2 uvt = (uvn + V.yx * v2random(vec2(uvn.y, time))) * vec2(0.1, 1.0);
    float n0 = v2random(uvt);
    float n1 = v2random(uvt + V.yx / VHSRES.x);
    if(n1 < n0) {
      col = mix(col, 2.0 * V.yyy, pow(n0, 5.0));
    }
  }
  // switching color modification
  col = mix(col, col.yzx, snPhase * 0.4);
  // ac beat
  col *= 1.0 + 0.1 * smoothstep(0.4, 0.6, v2random(vec2(0.0, 0.1 * (uv.y + time * 0.2)) / 10.0 * ac_beat));
  // color bleeding
  if(enable_bleed) {
    for(int x = -5; x < 2; x++) {
      col.xyz += vec3(vhsTex2D(uvn + vec2(float(x) - bleed_offset.x, 0.0) / VHSRES).x, vhsTex2D(uvn + vec2(float(x) - bleed_offset.y, 0.0) / VHSRES).y, vhsTex2D(uvn + vec2(float(x) - bleed_offset.z, 0.0) / VHSRES).z) * 0.25 * color_bleeding;
    }
    col *= 0.5 / (0.5 + color_bleeding);
  }
  // color noise, colormod
  // col *= 0.9 + 0.1 * texture2D(adsk_results_pass1, mod(uvn * vec2(.2, 1.0) + time * vec2(0.97, 0.45), vec2(1.0))).xyz;
  col *= 0.9 + 0.1 * texture2D(adsk_results_pass1, uv).rgb;
  col = saturate(col);
  // yiq
  if(enable_tint) {
    vec3 col_org = col;
    col = rgb2yiq(col);
    col = vec3(0.1, -0.1, 0.0) + vec3(yiq_offset) * col;
    col = yiq2rgb(col);
    col = mix(col_org, col, yiq_blend);
  }
  gl_FragColor = vec4(col, 1.0);
}
