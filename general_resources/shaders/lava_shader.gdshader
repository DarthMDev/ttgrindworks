// NOTE: Shader automatically converted from Godot Engine 4.3.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
instance uniform float speed = 1.0;

uniform vec4 heat_color : source_color;

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;

uniform float height_scale = 0.5;
uniform sampler2D displacement;

varying vec2 tex_position;
varying float vertex_displacement;

uniform vec3 emission_color;

void vertex() {
	UV = UV * uv1_scale.xy + uv1_offset.xy;
	UV.x += (TIME * 0.1 * speed);

	tex_position = VERTEX.xz / 2.0 + 0.5 + (TIME * 0.02);
	float height = texture(displacement, tex_position).x;
	vertex_displacement = height * height_scale;
	VERTEX.y += vertex_displacement;
}

void fragment() {
	vec2 base_uv = UV;

	vec4 albedo_tex = texture(texture_albedo, base_uv);

	// Vertex Color Use as Albedo: Enabled
	albedo_tex *= mix(COLOR, heat_color, sin(TIME));

	float darkening = vertex_displacement * 3.0;
	vec3 dark_vec = vec3(mix(0.6, 2.0, darkening));

	ALBEDO = albedo.rgb * albedo_tex.rgb * dark_vec.rgb;

	METALLIC = 0.0;
	SPECULAR = 0.0;
	ROUGHNESS = 0.0;
	EMISSION = emission_color;
}
