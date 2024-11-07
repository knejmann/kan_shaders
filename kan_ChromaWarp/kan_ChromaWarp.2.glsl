#version 120
uniform float adsk_result_w, adsk_result_h;
uniform float inner_diameter;
uniform float outer_diameter;
uniform float width_ratio;
uniform bool alternateMatte;
float strength;

// bool alternateMatte true;
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

    if(alternateMatte) {
        vec2 uv = gl_FragCoord.xy / vec2(adsk_result_w, adsk_result_h);
        uv *= 1.0 - uv;
        strength = pow(0.4 * uv.x * uv.y * inner_diameter, outer_diameter);

    }
    gl_FragColor = vec4(strength);
}

/* 

Todo: Dropdown med valg af vignette-algoritme?

Shadertoys

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    
    uv *= ( 1.0 - uv);   //vec2(1.0)- uv.yx; -> 1.-u.yx; Thanks FabriceNeyret !
    
    float vig = uv.x*uv.y * 4.0; // multiply with sth for intensity
    
    vig = pow(vig, 0.1); // change pow for modifying the extend of the  vignette

    
    fragColor = vec4(vig); 
} */