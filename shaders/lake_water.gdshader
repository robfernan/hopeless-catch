shader_type spatial;
render_mode cull_disabled, specular_disabled;

uniform vec3 surface_color : source_color = vec3(0.396078, 0.674510, 0.698039);
uniform vec3 depth_color : source_color = vec3(0.070588, 0.180392, 0.211765);
uniform vec3 edge_color : source_color = vec3(0.117647, 0.290196, 0.321569);
uniform sampler2D _foam : source_color, filter_linear, repeat_enable;
uniform float foam_mix : hint_range(0.0, 1.0) = 0.22;

void fragment() {
	vec2 uv = UV * 10.0 + vec2(TIME * 0.012, TIME * 0.007);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.4);
	vec3 body = mix(depth_color, surface_color, 0.62);
	body = mix(body, edge_color, fres * 0.55);
	vec4 ripple = texture(_foam, uv);
	ALBEDO = mix(body, ripple.rgb, foam_mix * ripple.a);
	ROUGHNESS = 0.94;
	METALLIC = 0.0;
}
