shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;

uniform float height_scale = 0.5;
uniform sampler2D displacement;

varying vec2 tex_position;
varying float vertex_displacement;

void vertex() {
	UV = UV * uv1_scale.xy + uv1_offset.xy;

	tex_position = VERTEX.xz / 2.0 + 0.5 + (TIME * 0.02);
	float height = texture(displacement, tex_position).x;
	vertex_displacement = height * height_scale;


	VERTEX.x += vertex_displacement;
}

void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo, base_uv);

	float brightness = 1.0 + vertex_displacement / 0.5;
	brightness = clamp(brightness, 1.0, 2.0);

	ALBEDO = albedo.rgb * albedo_tex.rgb * brightness;
}
