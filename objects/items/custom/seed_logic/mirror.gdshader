shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

void vertex() {}

void fragment() {
	vec2 _uv = SCREEN_UV;
	_uv.x = 1.0 - _uv.x;
	COLOR.rgb = textureLod(screen_texture, _uv, 0.0).rgb;
}
