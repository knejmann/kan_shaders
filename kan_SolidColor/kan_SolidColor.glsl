// Kaare Nejmann 2025
// Description: A shader that outputs a solid color.

uniform vec3 colorOne;
uniform vec3 colorTwo;
uniform bool useColorTwo;

void main(void) {
	vec3 color = useColorTwo ? colorTwo : colorOne;
	gl_FragColor = vec4(color, 1.0);
}
