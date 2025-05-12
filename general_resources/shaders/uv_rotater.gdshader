shader_type canvas_item;

uniform float speed = 60.0;

void fragment() {
	vec2 uv = UV;
	int state = int(TIME * speed) % 4;
	
	if (state == 1 || state == 3) {
		// Mirror
		uv.x = 1.0 - uv.x;
	}
	if (state == 2 || state == 3) {
		// Upside D
		uv.y = 1.0 - uv.y;
	}
	COLOR = texture(TEXTURE, uv);
}
