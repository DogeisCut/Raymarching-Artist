// **** Booleans ****
float union(float a, float b){
	return min(a,b);
}

float smoothUnion(float d1, float d2, float k){
	float h = clamp(0.5 + 0.5*(d2-d1)/k, 0.0, 1.0);
	return mix(d2, d1, h) - k*h*(1.0-h);
}

float subtraction(float a, float b){
	return max(-a,b);
}

float smoothSubtraction(float d1, float d2, float k){
	float h = clamp(0.5 - 0.5*(d2+d1)/k, 0.0, 1.0);
	return mix(d2, -d1, h) + k*h*(1.0-h);
}

float intersection(float a, float b){
	return max(a,b);
}

float smoothIntersection(float d1, float d2, float k){
	float h = clamp(0.5 - 0.5*(d2+d1)/k, 0.0, 1.0);
	return mix(d2, d1, h) + k*h*(1.0-h);
}