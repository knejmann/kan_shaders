#version 460
// shader version 1
#ifdef GL_ES
precision mediump float;
// vec4 fl_Coord = gl_FragCoord;
#endif

// inputs
uniform float adsk_result_w, adsk_result_h;
uniform sampler2D source;

// values from UI
uniform vec2 measureCenterUV;
uniform int measureSize;

// debugging

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

    if(all(lessThan(uv, vec2(0.01)))) {
        lum = calculateAverageLuminance(measureCenterUV, measureSize); // kald funktionen, der måler gennemsnit-lum i det definerede område
    }

    gl_FragColor = vec4(vec3(lum), 1.0);

}
