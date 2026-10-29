shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform bool enabled = true;
uniform float target_width = 480.0;
uniform float color_depth : hint_range(2.0, 32.0) = 8.0;
uniform float dither_strength : hint_range(0.0, 0.05) = 0.008;

int get_bayer_4x4(ivec2 p) {
	const int bayer[16] = {
		-4,  0, -3,  1,
		 2, -2,  3, -1,
		-3,  1, -4,  0,
		 3, -1,  2, -2
	};
	int x = p.x % 4;
	int y = p.y % 4;
	return bayer[y * 4 + x];
}

void fragment() {
	if (!enabled) {
		COLOR = texture(screen_texture, SCREEN_UV);
	} else {
		// Pixelate screen coordinates
		vec2 screen_size = vec2(target_width, target_width * (SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y));
		vec2 pixelated_uv = floor(SCREEN_UV * screen_size) / screen_size;
		
		vec3 color = texture(screen_texture, pixelated_uv).rgb;
		
		// Apply Bayer Dither
		ivec2 pixel_coord = ivec2(floor(SCREEN_UV * screen_size));
		float dither = float(get_bayer_4x4(pixel_coord)) * dither_strength;
		color += vec3(dither);
		
		// Quantize colors to retro palette
		color = floor(color * color_depth) / color_depth;
		
		COLOR = vec4(color, 1.0);
	}
}
