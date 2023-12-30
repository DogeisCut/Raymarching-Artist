struct Surface {
	float signedDistanceValue;
	vec3 color;
	float roughness;
	float metallicity;
	float emission;
	int marches;
};

Surface new_surface(float sdf, vec3 color, float roughness, float metallicity, float emission) {
	return Surface(sdf, color, roughness, metallicity, emission, 0);
}
