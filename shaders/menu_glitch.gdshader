shader_type canvas_item;

// burst 由脚本驱动：平时为 0，短暂脉冲时让个别横带错位，模拟信号损坏。
uniform float burst : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float band = floor(UV.y * 16.0);
	float seed = floor(TIME * 3.0);
	float r = fract(sin(band * 12.9898 + seed * 78.233) * 43758.5453);
	float shift = (r - 0.5) * 0.03 * burst * step(0.55, r);
	COLOR = texture(TEXTURE, vec2(UV.x + shift, UV.y));
}
