shader_type spatial;

render_mode cull_disabled;

uniform sampler2D sprite_sheet;
uniform int hframes = 4;
uniform int vframes = 4;
uniform float anim_speed = 8.0;

void fragment() {
    float total_frames = float(hframes * vframes);
    float frame = floor(TIME * anim_speed);
    frame = mod(frame, total_frames);

    float fx = mod(frame, float(hframes));
    float fy = floor(frame / float(hframes));

    vec2 frame_uv = UV / vec2(float(hframes), float(vframes));
    frame_uv += vec2(fx, fy) / vec2(float(hframes), float(vframes));

    vec4 tex = texture(sprite_sheet, frame_uv);

    ALBEDO = tex.rgb * COLOR.rgb;
    ALPHA  = tex.a * COLOR.a;
}

