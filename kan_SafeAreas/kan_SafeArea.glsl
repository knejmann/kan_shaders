uniform sampler2D  source;
uniform     float  adsk_result_w, adsk_result_h;

uniform      bool show_safe;
uniform      vec3 line_color_rgb;
vec4 line_color = vec4( line_color_rgb, 1.0);

uniform bool show_credit_minHeight;
uniform vec3 credit_color_rgb;
vec4 credit_color = vec4( credit_color_rgb, 1.00);

void main(void) {

    // Convert pixel coords to UV position for texture2D
    // and fetch the input pixel into px
    vec2 uv  = gl_FragCoord.xy / vec2( adsk_result_w, adsk_result_h );
    vec4 px  = vec4( texture2D( source, uv ).rgb, 1.0 );
    
    // Konverter koordinater, så vi kan bruge HD-koordinater for stregerne nedenfor - også selv om billedstørrelsen er anderledes.
    vec2 hd = floor(gl_FragCoord.xy / vec2(adsk_result_w/1920.0, adsk_result_h/1080.0));

    gl_FragColor = px;

if ( show_safe ) {
    // venstre side
    if( hd.x == 120 && hd.y >= 240 && hd.y <= 1080-220 )
        gl_FragColor = line_color;

    // højre side
    if( hd.x == 1920-120 && hd.y >= 240 && hd.y <= 1080-60 )
        gl_FragColor = line_color;

    // midt lodret
    if( hd.x == 120+840 && hd.y >= 1080-220 && hd.y <= 1080-60 )
        gl_FragColor = line_color;

    // top venstre
    if( hd.x >= 120 && hd.x <= 120+840 && hd.y == 1080-220 )
        gl_FragColor = line_color;

    // top højre
    if( hd.x >= 120+840 && hd.x <= 1920-120 && hd.y == 1080-60 )
        gl_FragColor = line_color;

    // bund
    if( hd.x >= 120 && hd.x <= 1920-120 && hd.y == 240 )
        gl_FragColor = line_color;
    }

if (show_credit_minHeight) {
        // min højde for creditbaggrund
    if( hd.y == 290 )
        gl_FragColor = credit_color;

        // venstre side
    if( hd.x == 120 && hd.y >= 60 && hd.y <= 260 )
        gl_FragColor = credit_color;

    // højre side
    if( hd.x == 1920-120 && hd.y >= 60 && hd.y <= 260 )
        gl_FragColor = credit_color;

    // top
    if( hd.x >= 120 && hd.x <= 1920-120 && hd.y == 260 )
        gl_FragColor = credit_color;

    // bund
    if( hd.x >= 120 && hd.x <= 1920-120 && hd.y == 60 )
        gl_FragColor = credit_color;
    }


}