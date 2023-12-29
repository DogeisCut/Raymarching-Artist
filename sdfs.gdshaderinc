#include "res://global.gdshaderinc"

float sdSphere(vec3 p, float r){
	return length(p) - r;
}

float sdBox(vec3 p, vec3 b)
{
	vec3 q = abs(p) - b;
	return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdRoundBox(vec3 p, vec3 b, float r)
{
	vec3 q = abs(p) - b;
	return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0) - r;
}

float sdCone(vec3 p, vec2 c, float h)
{
	vec2 q = h * vec2(c.x / c.y, -1.0);

	vec2 w = vec2(length((p).xz), (p).y);
	vec2 a = w - q * clamp(dot(w, q) / dot(q, q), 0.0, 1.0);
	vec2 b = w - q * vec2(clamp(w.x / q.x, 0.0, 1.0), 1.0);
	float k = sign(q.y);
	float d = min(dot(a, a), dot(b, b));
	float s = max(k * (w.x * q.y - w.y * q.x), k * (w.y - q.y));
	return sqrt(d) * sign(s);
}

float sdTorus(vec3 p, vec2 t)
{
	vec2 q = vec2(length((p).xz) - t.x, (p).y);
	return length(q) - t.y;
}

float sdPlane(vec3 p, vec3 n, float h)
{
	// n must be normalized
	return dot(p, n) + h;
}

float sdCapsule(vec3 p, vec3 a, vec3 b, float r)
{
	vec3 pa = p - a, ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h) - r;
}

float sdCappedCylinder(vec3 p, vec3 a, vec3 b, float r)
{
	vec3 ba = b - a;
	vec3 pa = p - a;
	float baba = dot(ba, ba);
	float paba = dot(pa, ba);
	float x = length(pa * baba - ba * paba) - r * baba;
	float y = abs(paba - baba * 0.5) - baba * 0.5;
	float x2 = x * x;
	float y2 = y * y * baba;
	float d = (max(x, y) < 0.0) ? -min(x2, y2) : (((x > 0.0) ? x2 : 0.0) + ((y > 0.0) ? y2 : 0.0));
	return sign(d) * sqrt(abs(d)) / baba;
}

float sdRoundedCylinder(vec3 p, float ra, float rb, float h)
{
	vec2 d = vec2(length((p).xz) - 2.0 * ra + rb, abs((p).y) - h);
	return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - rb;
}

float sdRoundCone(vec3 p, float r1, float r2, float h)
{
	float b = (r1 - r2) / h;
	float a = sqrt(1.0 - b * b);

	vec2 q = vec2(length((p).xz), (p).y);
	float k = dot(q, vec2(-b, a));
	if (k < 0.0)
		return length(q) - r1;
	if (k > a * h)
		return length(q - vec2(0.0, h)) - r2;
	return dot(q, vec2(a, b)) - r1;
}

float sdEllipsoid(vec3 p, vec3 r)
{
	float k0 = length((p) / r);
	float k1 = length((p) / (r * r));
	return k0 * (k0 - 1.0) / k1;
}
