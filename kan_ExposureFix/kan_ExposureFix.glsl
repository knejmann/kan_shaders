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
uniform bool showMeasurement;
uniform float expo_o;
uniform float targetLuminance;

uniform bool showArea;
uniform bool debug;

uniform vec2 measureCenterUV;
uniform int measureSize;

// debugging
uniform bool fromTlog;

// weights of rgb when calculating luminance

float luminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

// functions to convert lin to log and back
vec4 convertToLinear(vec4 val)
{
    float w = 128.0;
    float g = 16.0;
    float o = 0.075;

    // Constants
    float b = 1.0/(0.7107 + 1.2359*log(w*g));
    float gs = g/(1.0 - o);
    float C = b/gs;
    float a = 1.0 - b*log(w+C);
    float y0 = a + b*log(C);
    float s = (1.0 - o)/(1.0 - y0);
    float A = 1.0 + (a - 1.0)*s;
    float B = b*s;
    float G = gs*s;

    // Clip so output fits half float limit
    vec3 P = clamp(val.rgb, -60000.0, 1.86);

    P.r = P.r < o ? (P.r-o)/G : exp((P.r -A)/B) - C;
    P.g = P.g < o ? (P.g-o)/G : exp((P.g -A)/B) - C;
    P.b = P.b < o ? (P.b-o)/G : exp((P.b -A)/B) - C;

    return vec4(P, 1.);
}

float convertToLinearFloat(float val)
{
    float w = 128.0;
    float g = 16.0;
    float o = 0.075;

    // Constants
    float b = 1.0/(0.7107 + 1.2359*log(w*g));
    float gs = g/(1.0 - o);
    float C = b/gs;
    float a = 1.0 - b*log(w+C);
    float y0 = a + b*log(C);
    float s = (1.0 - o)/(1.0 - y0);
    float A = 1.0 + (a - 1.0)*s;
    float B = b*s;
    float G = gs*s;

    // Clip so output fits half float limit
    float P = clamp(val, -60000.0, 1.86);

    P = P < o ? (P-o)/G : exp((P -A)/B) - C;

    return float(P);
}

vec4 convertFromLinear(vec4 val)
{
    float w = 128.0;
    float g = 16.0;
    float o = 0.075;

    // Constants
    float b = 1.0/(0.7107 + 1.2359*log(w*g));
    float gs = g/(1.0 - o);
    float C = b/gs;
    float a = 1.0 - b*log(w+C);
    float y0 = a + b*log(C);
    float s = (1.0 - o)/(1.0 - y0);
    float A = 1.0 + (a - 1.0)*s;
    float B = b*s;
    float G = gs*s;

    val.r = val.r < 0.0 ? G*val.r + o : log(val.r + C)*B + A; 
    val.g = val.g < 0.0 ? G*val.g + o : log(val.g + C)*B + A; 
    val.b = val.b < 0.0 ? G*val.b + o : log(val.b + C)*B + A; 

    return val;
}

vec4 convertFromLinearFloat(float val)
{
    float w = 128.0;
    float g = 16.0;
    float o = 0.075;

    // Constants
    float b = 1.0/(0.7107 + 1.2359*log(w*g));
    float gs = g/(1.0 - o);
    float C = b/gs;
    float a = 1.0 - b*log(w+C);
    float y0 = a + b*log(C);
    float s = (1.0 - o)/(1.0 - y0);
    float A = 1.0 + (a - 1.0)*s;
    float B = b*s;
    float G = gs*s;

    val = val < 0.0 ? G*val + o : log(val + C)*B + A; 

    return val;
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

float drawMeasureArea(vec2 pixel, vec2 center, int size) {
    float a = 0. ;
    vec2 nsize = vec2(size) / textureSize(source, 0); // size = radius på den indskrevne cirkel i kvadratet, der måles i, i pixels. nsize er normaliseret.
    vec2 cpixel = abs(pixel - center); // range 0

    // if ( cpixel.x <= nsize.x && cpixel.y <= nsize.y)
    if ( all(lessThanEqual(cpixel, nsize)))  // lessThanEqual returnerer en boolean vector. all: Hvis alle er true returneres true.
        a = 1.;
    return a;
}

void main(void) {
    // vec2 uv = gl_TexCoord[0].xy;
    // vec2 uv = fl_UVCoord;
    vec2 uv = vec2(gl_FragCoord.x/adsk_result_w, gl_FragCoord.y/adsk_result_h);
    vec3 col = texture2D(source, uv).rgb;
    // col = vec3 gl_FragColor;
    // overall exposure adjustemnt
    col = col * pow(2.0, expo_o); // manuel eksponerings-justering

    float lum = calculateAverageLuminance( measureCenterUV, measureSize); // kald funktionen, der måler gennemsnit-lum i det definerede område
    
    // float lum_disp = log2(lum + 1) / 5. ; // lum-værdi skaleret så der er plads til en del stops. Bruges til at vise bar.
    // float lum_disp = log2(11*lum + 1 ) / 9. ; // lum-værdi skaleret så der er plads til en del stops. Bruges til at vise bar.
    // float lum_disp = log(lum + .0057 ) * 0.0923 + 0.55 ; // lum-værdi skaleret så der er plads til en del stops. Bruges til at vise bar.
    float lum_disp = convertFromLinearFloat(lum) ; // lum-værdi skaleret så der er plads til en del stops. Bruges til at vise bar.
    
    // float scaledTarget = log2(1+(targetLuminance)) /5. ;//
    // float scaledTarget = exp2(targetLuminance * 5) - 1 ;//

    float exposureComp = convertToLinearFloat(targetLuminance / 1920.) / lum; // virker når viewport er 1920 bred

    col *= exposureComp;

    // if(debug && uv.y <= 0.05 && uv.x <= lum / 100.)
    if(debug && uv.y <= 0.05 && gl_FragCoord.x <= lum * 10.)
        col = vec3(1., 0., 0.);
    

    if(showMeasurement && uv.y < 1 && uv.y >= 0.95 && uv.x <= lum_disp)
        col = vec3(1., .0, 0.);

    if(showArea) {
        float a = drawMeasureArea(uv, measureCenterUV, measureSize);
        float b = drawMeasureArea(uv, measureCenterUV, measureSize+1);
        
        col = mix(col, vec3(0.9843, 1.0, 0.0), b-a ) ;
        }

    gl_FragColor = vec4(col, 1.0);

}
