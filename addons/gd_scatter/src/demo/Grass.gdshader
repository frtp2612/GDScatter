shader_type spatial;

uniform float time_scale = 0.5;
uniform float side_to_side = 0.001;
uniform float pivot = 2.5;
uniform float wave = 0.008;
uniform float twist = 1;
uniform float mask_black = 0;
uniform float mask_white = 1;

uniform vec4 base_color : hint_color;
uniform vec4 top_color : hint_color;
uniform sampler2D color_mask;

void vertex() {
	float time = (TIME * time_scale) + (6.28318 * INSTANCE_CUSTOM.x);
	
	float pivot_angle = cos(time) * 0.1 * pivot;
	mat2 rotation_matrix = mat2(vec2(cos(pivot_angle), -sin(pivot_angle)), vec2(sin(pivot_angle), cos(pivot_angle)));

	float body = (VERTEX.z + 1.0) / 2.0;
	
	float twist_angle = cos(time + body) * 0.3 * twist;
	mat2 twist_matrix = mat2(vec2(cos(twist_angle), -sin(twist_angle)), vec2(sin(twist_angle), cos(twist_angle)));

	float mask = smoothstep(mask_black, mask_white, 1.0 - body);
	VERTEX.x += cos(time) * side_to_side;
//	VERTEX.xz += rotation_matrix * VERTEX.xz;
	VERTEX.x += cos(time + body) * mask * wave;
//	VERTEX.xy += mix(VERTEX.xy, twist_matrix * VERTEX.xy, mask);
	COLOR = mix(base_color, top_color, UV2.y);
}

void fragment() {
//	COLOR is the vertex
	ALBEDO = texture(color_mask, UV).rgb * base_color.rgb;
//	ALBEDO = mix(COLOR.rgb, texture(color_mask, UV).rgb, 0.5);
}