#include "res://global.gdshaderinc"

// **** Booleans/CSG Operations ****
Surface union(Surface a, Surface b){
	//This is basically min(a,b)
	if (b.signedDistanceValue < a.signedDistanceValue) return b; 
	return a;
}

Surface smoothUnion(Surface s1, Surface s2, float k) {
	float h = clamp(0.5 + 0.5 * (s2.signedDistanceValue - s1.signedDistanceValue) / k, 0.0, 1.0);
	
	Surface result;
	result.signedDistanceValue = mix(s2.signedDistanceValue, s1.signedDistanceValue, h) - k * h * (1.0 - h);
	result.color = mix(s2.color, s1.color, h);
	result.roughness = mix(s2.roughness, s1.roughness, h);
	result.metallicity = mix(s2.metallicity, s1.metallicity, h);
	
	return result;
}

Surface subtraction(Surface a, Surface b) {
	//This is basically max(-a,b)
	Surface result;
	result.signedDistanceValue = max(-a.signedDistanceValue, b.signedDistanceValue);
	result.color = b.color;  // Keep the color of the subtracted object
	result.roughness = b.roughness;  // Keep the roughness of the subtracted object
	result.metallicity = b.metallicity;  // Keep the metallicity of the subtracted object
	return result;
}


Surface smoothSubtraction(Surface s1, Surface s2, float k) {
	float h = clamp(0.5 - 0.5 * (s2.signedDistanceValue + s1.signedDistanceValue) / k, 0.0, 1.0);
	
	Surface result;
	result.signedDistanceValue = mix(s2.signedDistanceValue, -s1.signedDistanceValue, h) + k * h * (1.0 - h);
	result.color = s2.color;  // Keep the color of the subtracted object
	result.roughness = s2.roughness;  // Keep the roughness of the subtracted object
	result.metallicity = s2.metallicity;  // Keep the metallicity of the subtracted object
	
	return result;
}

Surface intersection(Surface a, Surface b) {
	//This is basically max(a,b)
	Surface result;
	result.signedDistanceValue = max(a.signedDistanceValue, b.signedDistanceValue);
	result.color = a.color;  // Keep the color of the intersected object
	result.roughness = a.roughness;  // Keep the roughness of the intersected object
	result.metallicity = a.metallicity;  // Keep the metallicity of the intersected object
	return result;
}

Surface smoothIntersection(Surface s1, Surface s2, float k) {
	float h = clamp(0.5 - 0.5 * (s2.signedDistanceValue + s1.signedDistanceValue) / k, 0.0, 1.0);
	
	Surface result;
	result.signedDistanceValue = mix(s2.signedDistanceValue, s1.signedDistanceValue, h) + k * h * (1.0 - h);
	result.color = mix(s2.color, s1.color, h);
	result.roughness = mix(s2.roughness, s1.roughness, h);
	result.metallicity = mix(s2.metallicity, s1.metallicity, h);
	
	return result;
}