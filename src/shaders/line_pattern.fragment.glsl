uniform vec2 u_texsize;
uniform float u_fade;
uniform vec4 u_scale;
uniform bool u_zoomin;

uniform sampler2D u_image;

varying vec2 v_normal;
varying vec2 v_width2;
varying float v_linesofar;
varying float v_gamma_scale;

#pragma mapbox: define mediump vec4 pattern_min
#pragma mapbox: define mediump vec4 pattern_mid
#pragma mapbox: define mediump vec4 pattern_max
#pragma mapbox: define lowp float blur
#pragma mapbox: define lowp float opacity

void main() {
    #pragma mapbox: initialize mediump vec4 pattern_min
    #pragma mapbox: initialize mediump vec4 pattern_mid
    #pragma mapbox: initialize mediump vec4 pattern_max

    #pragma mapbox: initialize lowp float blur
    #pragma mapbox: initialize lowp float opacity

    vec2 u_pattern_tl_a = u_zoomin ? pattern_min.xy : pattern_max.xy;
    vec2 u_pattern_br_a = u_zoomin ? pattern_min.zw : pattern_max.zw;
    vec2 u_pattern_tl_b = pattern_mid.xy;
    vec2 u_pattern_br_b = pattern_mid.zw;

    float pixelRatio = u_scale.x;
    float tileRatio = u_scale.y;
    float fromScale = u_scale.z;
    float toScale = u_scale.w;

    vec2 display_size_a = vec2((u_pattern_br_a.x - u_pattern_tl_a.x) / pixelRatio, (u_pattern_br_a.y - u_pattern_tl_a.y) / pixelRatio);
    vec2 display_size_b = vec2((u_pattern_br_b.x - u_pattern_tl_b.x) / pixelRatio, (u_pattern_br_b.y - u_pattern_tl_b.y) / pixelRatio);

    vec2 u_pattern_size_a = vec2(display_size_a.x * fromScale / tileRatio, display_size_a.y);
    vec2 u_pattern_size_b = vec2(display_size_b.x * toScale / tileRatio, display_size_b.y);

    // Calculate the distance of the pixel from the line in pixels.
    float dist = length(v_normal) * v_width2.s;

    // Calculate the antialiasing fade factor. This is either when fading in
    // the line in case of an offset line (v_width2.t) or when fading out
    // (v_width2.s)
    float blur2 = (blur + 1.0 / DEVICE_PIXEL_RATIO) * v_gamma_scale;
    float alpha = clamp(min(dist - (v_width2.t - blur2), v_width2.s - dist) / blur2, 0.0, 1.0);

    float x_a = mod(v_linesofar / u_pattern_size_a.x, 1.0);
    float x_b = mod(v_linesofar / u_pattern_size_b.x, 1.0);

    // v_normal.y is 0 at the midpoint of the line, -1 at the lower edge, 1 at the upper edge
    // we clamp the line width outset to be between 0 and half the pattern height plus padding (2.0)
    // to ensure we don't sample outside the designated symbol on the sprite sheet.
    // 0.5 is added to shift the component to be bounded between 0 and 1 for interpolation of
    // the texture coordinate
    float y_a = 0.5 + (v_normal.y * clamp(v_width2.s, 0.0, (u_pattern_size_a.y + 2.0) / 2.0) / u_pattern_size_a.y);
    float y_b = 0.5 + (v_normal.y * clamp(v_width2.s, 0.0, (u_pattern_size_b.y + 2.0) / 2.0) / u_pattern_size_b.y);
    vec2 pos_a = mix(u_pattern_tl_a / u_texsize, u_pattern_br_a / u_texsize, vec2(x_a, y_a));
    vec2 pos_b = mix(u_pattern_tl_b / u_texsize, u_pattern_br_b / u_texsize, vec2(x_b, y_b));

    vec4 color = mix(texture2D(u_image, pos_a), texture2D(u_image, pos_b), u_fade);

    gl_FragColor = color * alpha * opacity;

#ifdef OVERDRAW_INSPECTOR
    gl_FragColor = vec4(1.0);
#endif
}
