#version 120
uniform float adsk_result_w, adsk_result_h;
uniform float inner_diameter;
uniform float outer_diameter;
uniform float width_ratio;

float strength;
// uniform sampler2D chroma_strength;

// void main()
// {
// 	vec2 uv = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h);
// 	float a = texture2D(chroma_strength, uv).r;
// 	gl_FragColor = vec4(a);
// }

void main() {
	vec2 uvc = (gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h)) - vec2(0.5);
	// float a = texture2D(chroma_strength, uv).r;
	vec2 aspect = vec2(width_ratio, 1);
	float dist = distance(uvc * aspect, vec2(0.0));
	//strength = clamp((dist - inner_diameter) * outer_diameter, 0.0, 1.0);
	strength = smoothstep(inner_diameter, outer_diameter, dist);
	gl_FragColor = vec4(0 + strength);
}
