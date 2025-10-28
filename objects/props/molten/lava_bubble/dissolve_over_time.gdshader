shader_type spatial;

render_mode cull_back;

uniform sampler2D texture_albedo : source_color;
uniform sampler2D noise_tex;
uniform sampler2D curve_tex;

varying float lifetime;

void vertex() {
    lifetime = INSTANCE_CUSTOM.y;
}

void fragment() {
    vec2 base_uv = UV;

    vec4 albedo_tex = texture(texture_albedo, base_uv);
    albedo_tex *= COLOR;

    ALBEDO = albedo_tex.rgb;

    float alpha = albedo_tex.a;

    float erosion_val = texture(noise_tex, UV).r;
    float curve_val = texture(curve_tex, vec2(lifetime, 0.0)).r;

    float dissolve = smoothstep(curve_val, curve_val + 0.06, erosion_val);

    ALPHA = alpha * (1.0 - dissolve);
}
