shader_type canvas_item;

render_mode unshaded;

uniform sampler2D tex : source_color;  // Texture, used as color

uniform float radius = 0.0; // Radius of the circle
uniform float feather = 0.05; // Feathering of the circles edge

uniform vec2 origin = vec2(0.5, 0.5); // Center (Adjust to move the circle around)

float circle_mask(vec2 _uv, vec2 _origin, float _radius, float _feather) {
	float dist = length(_uv - _origin); // Distance from current pixel to the origin
	return smoothstep(_radius, _radius - _feather, dist/1.5); // Smooth transition
}

void fragment() {
	COLOR = texture(tex, UV);
	COLOR.a = min(circle_mask(UV, origin, radius, feather), COLOR.a);
}
