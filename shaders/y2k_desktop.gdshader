shader_type canvas_item;

uniform float grid_strength : hint_range(0.0, 1.0) = 0.07;
uniform float scan_strength : hint_range(0.0, 1.0) = 0.09;
uniform float flicker_strength : hint_range(0.0, 1.0) = 0.03;
uniform float grid_scale : hint_range(8.0, 128.0) = 36.0;
uniform float scan_scale : hint_range(180.0, 1080.0) = 720.0;

void fragment() {
	float grid_x = step(0.985, fract(UV.x * grid_scale));
	float grid_y = step(0.985, fract(UV.y * grid_scale));
	float scan = step(0.5, fract(UV.y * scan_scale));
	float flicker = 0.5 + 0.5 * sin(TIME * 1.1);
	float alpha = clamp(
		grid_x * grid_strength + grid_y * grid_strength + scan * scan_strength + flicker * flicker_strength,
		0.0,
		0.22
	);
	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
