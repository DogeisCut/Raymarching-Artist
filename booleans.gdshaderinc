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
	result.emission = mix(s2.emission, s1.emission, h);
	
	return result;
}

Surface subtraction(Surface a, Surface b) {
	//This is basically max(-a,b)
	Surface result;
	result.signedDistanceValue = max(-a.signedDistanceValue, b.signedDistanceValue);
	result.color = b.color;  // Keep the color of the subtracted object
	result.roughness = b.roughness;  // Keep the roughness of the subtracted object
	result.metallicity = b.metallicity;  // Keep the metallicity of the subtracted object
	result.emission = b.emission;  // Keep the emission of the subtracted object
	return result;
}


Surface smoothSubtraction(Surface s1, Surface s2, float k) {
	float h = clamp(0.5 - 0.5 * (s2.signedDistanceValue + s1.signedDistanceValue) / k, 0.0, 1.0);
	
	Surface result;
	result.signedDistanceValue = mix(s2.signedDistanceValue, -s1.signedDistanceValue, h) + k * h * (1.0 - h);
	result.color = s2.color;  // Keep the color of the subtracted object
	result.roughness = s2.roughness;  // Keep the roughness of the subtracted object
	result.metallicity = s2.metallicity;  // Keep the metallicity of the subtracted object
	result.emission = s2.emission;  // Keep the metallicity of the subtracted object
	
	return result;
}

Surface intersection(Surface a, Surface b) {
	//This is basically max(a,b)
	Surface result;
	result.signedDistanceValue = max(a.signedDistanceValue, b.signedDistanceValue);
	result.color = a.color;  // Keep the color of the intersected object
	result.roughness = a.roughness;  // Keep the roughness of the intersected object
	result.metallicity = a.metallicity;  // Keep the metallicity of the intersected object
	result.emission = a.emission;  // Keep the emission of the intersected object
	return result;
}

Surface smoothIntersection(Surface s1, Surface s2, float k) {
	float h = clamp(0.5 - 0.5 * (s2.signedDistanceValue + s1.signedDistanceValue) / k, 0.0, 1.0);
	
	Surface result;
	result.signedDistanceValue = mix(s2.signedDistanceValue, s1.signedDistanceValue, h) + k * h * (1.0 - h);
	result.color = mix(s2.color, s1.color, h);
	result.roughness = mix(s2.roughness, s1.roughness, h);
	result.metallicity = mix(s2.metallicity, s1.metallicity, h);
	result.emission = mix(s2.emission, s1.emission, h);
	
	return result;
}

Surface paint(Surface s1, Surface s2) {
	Surface result;
	result.signedDistanceValue = s2.signedDistanceValue;
	result.color = mix(s1.color, s2.color, step(0.0, s1.signedDistanceValue));
	result.roughness = mix(s1.roughness, s2.roughness, step(0.0, s1.signedDistanceValue));
	result.metallicity = mix(s1.metallicity, s2.metallicity, step(0.0, s1.signedDistanceValue));
	result.emission = mix(s1.emission, s2.emission, step(0.0, s1.signedDistanceValue));
	
	return result;
}

Surface smoothPaint(Surface s1, Surface s2, float k) {
	Surface result;
	float transition = smoothstep(-k, k, s1.signedDistanceValue);
	
	result.signedDistanceValue = s2.signedDistanceValue;
	result.color = mix(s2.color, s1.color, transition);
	result.roughness = mix(s2.roughness, s1.roughness, transition);
	result.metallicity = mix(s2.metallicity, s1.metallicity, transition);
	result.emission = mix(s2.emission, s1.emission, transition);
	
	return result;
}
