shader_type spatial;
render_mode specular_schlick_ggx, depth_draw_always;

// Colors matching Sega Bass Fishing & About Fishing murky lake tones
uniform vec4 deep_color : source_color = vec4(0.03, 0.14, 0.16, 0.94);
uniform vec4 shallow_color : source_color = vec4(0.08, 0.38, 0.36, 0.75);
uniform vec4 foam_color : source_color = vec4(0.85, 0.95, 0.92, 1.0);

uniform float wave_speed : hint_range(0.0, 3.0) = 0.8;
uniform float wave_scale : hint_range(0.1, 10.0) = 1.6;
uniform float wave_height : hint_range(0.0, 0.5) = 0.05;

uniform float metallic : hint_range(0.0, 1.0) = 0.15;
uniform float roughness : hint_range(0.0, 1.0) = 0.12;

uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

// Procedural wave height function
float get_wave(vec2 uv, float time) {
	float w1 = sin(uv.x * wave_scale + time * wave_speed) * cos(uv.y * wave_scale * 0.8 + time * wave_speed * 0.7);
	float w2 = sin((uv.x + uv.y) * wave_scale * 1.4 - time * wave_speed * 1.1) * 0.5;
	float w3 = cos(uv.x * wave_scale * 2.2 - time * wave_speed * 0.9) * 0.25;
	return (w1 + w2 + w3) * wave_height;
}

// Procedural caustic pattern
float get_caustic(vec2 uv, float time) {
	vec2 p = uv * 3.5;
	float c1 = sin(p.x * 2.0 + sin(p.y * 3.0 + time * 1.2));
	float c2 = cos(p.y * 2.5 + cos(p.x * 3.5 + time * 1.0));
	return pow(clamp((c1 + c2) * 0.5 + 0.5, 0.0, 1.0), 3.0) * 0.35;
}

void vertex() {
	vec2 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
	float wave = get_wave(world_pos, TIME);
	VERTEX.y += wave;
	
	// Compute analytical normals for procedural waves
	float eps = 0.05;
	float h_x = get_wave(world_pos + vec2(eps, 0.0), TIME);
	float h_z = get_wave(world_pos + vec2(0.0, eps), TIME);
	vec3 tangent = normalize(vec3(eps, h_x - wave, 0.0));
	vec3 bitangent = normalize(vec3(0.0, h_z - wave, eps));
	NORMAL = normalize(cross(bitangent, tangent));
}

void fragment() {
	vec2 world_uv = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xz;
	
	// Sample scene depth behind water
	float depth_raw = texture(depth_texture, SCREEN_UV).r;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth_raw);
	vec4 view_pos = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view_pos.xyz /= view_pos.w;
	float linear_depth = -view_pos.z;
	float water_depth = clamp((linear_depth - (-VERTEX.z)) * 0.45, 0.0, 1.0);
	
	// Deep murky lake color gradient
	vec3 base_water = mix(shallow_color.rgb, deep_color.rgb, water_depth);
	
	// Add caustic light shimmer
	float caustics = get_caustic(world_uv, TIME);
	base_water += vec3(caustics * (1.0 - water_depth * 0.6));
	
	// Shoreline & dock edge foam
	float foam = 1.0 - smoothstep(0.0, 0.08, water_depth);
	vec3 final_color = mix(base_water, foam_color.rgb, foam * 0.7);
	
	// Fresnel grazing angle reflection
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
	
	ALBEDO = final_color;
	ALPHA = mix(shallow_color.a, deep_color.a, water_depth);
	METALLIC = metallic;
	ROUGHNESS = mix(roughness, 0.04, fresnel);
	SPECULAR = 0.8;
}
