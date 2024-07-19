#version 460
// shader version 2

// This first pass measures the average luminance of the pixels chosen.
// The output is a mostly black image where the pixels in the lower left corner is set to the measured luminance value.

// inputs
uniform float adsk_result_w, adsk_result_h; // width and height of the frame
uniform sampler2D source; // input video

// values from UI
uniform vec2 measureCenterUV; // range 0 - 1
uniform int measureSize; // range 1 - 100 (pixels each side of measureCenterUV)

// weights of rgb when calculating luminance
float luminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

// measure the average luminance of the measured pixels

float calculateAverageLuminance(vec2 measureCenterUV, int measureSize) {
    float totalLuminance = 0.0;
    int count = 0;

    for(int i = -measureSize; i <= measureSize; i++) {
        for(int j = -measureSize; j <= measureSize; j++) {
            vec2 offset = vec2(i, j) / textureSize(source, 0);
            vec4 color = texture2D(source, measureCenterUV + offset);
            float luminance = luminance(color.rgb);
            totalLuminance += luminance;
            count++;
        }
    }

    return totalLuminance / float(count);
}

void main(void) {
    vec2 uv = vec2(gl_FragCoord.x / adsk_result_w, gl_FragCoord.y / adsk_result_h);
    // vec3 col = texture2D(source, uv).rgb;

    float lum = .0;

// process only the pixels that are in the lower left corner (u and v less than 0.01) and set lum to the measured luminance.
// without this the calculateAverageLuminance is called once for every single pixel.
    if(all(lessThan(uv, vec2(0.01)))) {
        lum = calculateAverageLuminance(measureCenterUV, measureSize); // kald funktionen, der måler gennemsnit-lum i det definerede område
    }

    gl_FragColor = vec4(vec3(lum), 1.0);

}
