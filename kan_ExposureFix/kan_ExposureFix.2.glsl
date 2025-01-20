#version 460
// shader version 2

// this second pass adjusts the luminance of the source.

// inputs
uniform float adsk_result_w, adsk_result_h;
uniform sampler2D source;
uniform sampler2D adsk_results_pass1;

// values from UI
uniform bool showMeasurement;
uniform float expo_o;
uniform float targetLuminance;
uniform float effectBlending;

uniform bool showArea;
uniform bool debug;

uniform vec2 measureCenterUV;
uniform int measureSize;

// functions to convert lin to log and back

float convertToLinearFloat(float val) {
    float w = 128.0;
    float g = 16.0;
    float o = 0.075;

    // Constants
    float b = 1.0 / (0.7107 + 1.2359 * log(w * g));
    float gs = g / (1.0 - o);
    float C = b / gs;
    float a = 1.0 - b * log(w + C);
    float y0 = a + b * log(C);
    float s = (1.0 - o) / (1.0 - y0);
    float A = 1.0 + (a - 1.0) * s;
    float B = b * s;
    float G = gs * s;

    // Clip so output fits half float limit
    float P = clamp(val, -60000.0, 1.86);

    P = P < o ? (P - o) / G : exp((P - A) / B) - C;

    return float(P);
}

float convertFromLinearFloat(float val) {
    float w = 128.0;
    float g = 16.0;
    float o = 0.075;

    // Constants
    float b = 1.0 / (0.7107 + 1.2359 * log(w * g));
    float gs = g / (1.0 - o);
    float C = b / gs;
    float a = 1.0 - b * log(w + C);
    float y0 = a + b * log(C);
    float s = (1.0 - o) / (1.0 - y0);
    float A = 1.0 + (a - 1.0) * s;
    float B = b * s;
    float G = gs * s;

    val = val < 0.0 ? G * val + o : log(val + C) * B + A;

    return val;
}

float drawMeasureArea(vec2 pixel, vec2 center, int size) {
    float a = 0.;
    vec2 nsize = vec2(size) / textureSize(source, 0); // size = radius på den indskrevne cirkel i kvadratet, der måles i, i pixels. nsize er normaliseret.
    vec2 cpixel = abs(pixel - center); // range 0

    // if ( cpixel.x <= nsize.x && cpixel.y <= nsize.y)
    if(all(lessThanEqual(cpixel, nsize)))  // lessThanEqual returnerer en boolean vector. all: Hvis alle er true returneres true.
        a = 1.;
    return a;
}

void main(void) {
    // vec2 uv = gl_TexCoord[0].xy;
    // vec2 uv = fl_UVCoord;
    // vec2 xy = vec2(gl_FragCoord.x, adsk_result_h - gl_FragCoord.y);
    vec2 uv = vec2(gl_FragCoord.x / adsk_result_w, gl_FragCoord.y / adsk_result_h);
    // vec3 col = texture2DRect(source, xy).rgb;
    vec3 col = texture2D(source, uv).rgb;

    // overall exposure adjustemnt
    vec3 colMan = col * pow(2.0, expo_o); // manual adjustment of exposure

    // grab the luminance of one pixel in the output of pass_1. This is the measured luminance.
    float lum = texture2D(adsk_results_pass1, vec2(0.005)).r;

    // convert the lum value from linear to log. The purpose is to be able to plot the measured value along the x-axis. The actual function is borrowed from Filmlight Log-T.
    float lum_disp = convertFromLinearFloat(lum);

    // targetLuminance is divided by 1920 and converted from log to linear. This is then divided by the measured lum.
    float exposureComp = convertToLinearFloat(targetLuminance / 1920.) / lum; // virker når viewport er 1920 bred

    // multiply the color (RGB) by the exposureComp.
    vec3 colComp = colMan * exposureComp;

    // // if(debug && uv.y <= 0.05 && uv.x <= lum / 100.)
    // if(debug && uv.y <= 0.05 && gl_FragCoord.x <= lum * 10.)
    //     col = vec3(1., 0., 0.);

    // if enabled the measured luminance is plotted on the top 5% of the image as a red bar.
    if(showMeasurement && uv.y < 1 && uv.y >= 0.95 && uv.x <= lum_disp)
        colComp = vec3(1.0, 0.0, 0.0);

    // if showMeasurement is enabled the luminance target is plotted on the top 5-6% of the image as a green bar.
    if(showMeasurement && uv.y < 0.95 && uv.y >= 0.94 && uv.x <= (targetLuminance / 1920.))
        colComp = vec3(0.0, 0.5, 0.0);

    // if enabled the area where the luminance is measured is shown on screen.
    if(showArea) {
        float a = drawMeasureArea(uv, measureCenterUV, measureSize);
        float b = drawMeasureArea(uv, measureCenterUV, measureSize + 2);

        colComp = mix(colComp, vec3(0.8, 0.8, 0.1), b - a);
    }

    if(debug)
        // gl_FragColor = vec4(vec3(lum), 0.);
        gl_FragColor = texture2D(adsk_results_pass1, uv);
    else
        // gl_FragColor = vec4(colComp, 1.0);
        gl_FragColor = vec4(mix(col, colComp, effectBlending), 1.0);
}
