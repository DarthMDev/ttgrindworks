shader_type spatial;
render_mode world_vertex_coords;

uniform sampler2D albedo_texture: source_color;
uniform vec4 albedo_color: source_color;
uniform bool use_vertex_color_as_albedo;
uniform vec3 plane_position;
uniform vec3 plane_normal = vec3(0, 1, 0);
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;

uniform sampler2D texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;

uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);

void vertex() {
	UV = UV * uv1_scale.xy + uv1_offset.xy;
}

void fragment() {
	vec4 vertex = vec4(VERTEX, 1.0);
	vec4 view_hole_pos = VIEW_MATRIX * vec4(plane_position, 1.0);
	vec3 view_plane = mat3(VIEW_MATRIX) * plane_normal;

	if (dot(vertex - view_hole_pos, vec4(view_plane, 1.0)) < 0.0) {
		discard;
	}

	vec4 albedo_tex = texture(albedo_texture, UV);
	albedo_tex *= albedo_color;
	if (use_vertex_color_as_albedo) {
		albedo_tex *= COLOR;
	}

	ALBEDO = albedo_tex.rgb;
	#ifdef USE_ALPHA
	ALPHA = albedo_tex.a;
	#endif
	
	vec2 base_uv = UV;
	float metallic_tex = dot(texture(texture_metallic, base_uv), metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	SPECULAR = specular;
}
