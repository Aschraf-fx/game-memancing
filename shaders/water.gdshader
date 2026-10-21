shader_type spatial;
render_mode blend_mix, cull_disabled;

// Air low-poly: ombak kecil + permukaan bersegi (flat shading).
uniform vec4 water_color : source_color = vec4(0.07, 0.3, 0.34, 0.88);
uniform float wave_height = 0.05;
uniform float wave_speed = 1.0;

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += (sin(w.x * 0.7 + TIME * wave_speed) + cos(w.z * 0.9 + TIME * wave_speed * 1.3)) * wave_height;
}

void fragment() {
	vec3 n = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
	if (dot(n, VERTEX) > 0.0) {
		n = -n;
	}
	NORMAL = n;
	ALBEDO = water_color.rgb;
	ALPHA = water_color.a;
	ROUGHNESS = 0.15;
	SPECULAR = 0.4;
}
