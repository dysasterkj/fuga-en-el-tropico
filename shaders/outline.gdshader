shader_type spatial;
render_mode cull_front, unshaded;

// Contorno cartoon: casco invertido ligeramente inflado.
uniform float width = 0.03;
uniform vec4 color : source_color = vec4(0.04, 0.06, 0.12, 1.0);

void vertex() {
	VERTEX += NORMAL * width;
}

void fragment() {
	ALBEDO = color.rgb;
}
