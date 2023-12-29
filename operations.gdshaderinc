// **** Operations ****

mat2 opRotate(float a) {
	float s = sin(a);
	float c = cos(a);
	return mat2(vec2(c, -s), vec2(s, c));
}
vec3 opRepeat(vec3 p, vec3 c) {
	return mod(p, c) - 0.5 * c;
}
vec3 opTwist(vec3 p, float k)
{
	float c = cos(k * p.y);
	float s = sin(k * p.y);
	mat2  m = mat2(vec2(c, -s), vec2(s, c));
	return vec3(m*p.xz, p.y);
}
vec3 opBend(vec3 p, float k)
{
	float c = cos(k * p.x);
	float s = sin(k * p.x);
	mat2  m = mat2(vec2(c, -s), vec2(s, c));
	return vec3(m*p.xy, p.z);
}