shader_type canvas_item;

uniform float shaking: hint_range(0.0, 1.0) = 0.0;

void vertex() {
	float direction_angle = TIME * TAU;
	vec2 direction = vec2(cos(direction_angle), sin(direction_angle));
	VERTEX += direction * sin(10.0 * TIME * TAU) * shaking * 3.0;
}
