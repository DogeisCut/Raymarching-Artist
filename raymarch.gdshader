shader_type spatial;
render_mode unshaded, depth_test_disabled;

uniform int MAX_STEPS = 1000;
uniform float MAX_DIST = 1000.0;
uniform float SURF_DIST = 0.0001;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;

// **** booleans :) ****
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

// **** Primatives ****

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

// **** Operations ****

mat2 op_rotate(float a) {
	float s = sin(a);
	float c = cos(a);
	return mat2(vec2(c, -s), vec2(s, c));
}
vec3 op_repeat(vec3 p, vec3 c) {
	return mod(p, c) - 0.5 * c;
}
vec3 op_twist(vec3 p, float k)
{
	float c = cos(k * p.y);
	float s = sin(k * p.y);
	mat2  m = mat2(vec2(c, -s), vec2(s, c));
	return vec3(m*p.xz, p.y);
}
vec3 op_bend(vec3 p, float k)
{
	float c = cos(k * p.x);
	float s = sin(k * p.x);
	mat2  m = mat2(vec2(c, -s), vec2(s, c));
	return vec3(m*p.xy, p.z);
}

// **** The Scene SDF ****

float GetDist(vec3 p){
	vec3 boxPos = p-vec3(5,2,5);
	boxPos.xz *= op_rotate(TIME);
	//boxPos = op_twist(boxPos, 0.25);
	return union(smoothUnion(union(smoothUnion(sdSphere(p-vec3(0,1,0), 1), sdSphere(p-vec3(1,2,1), 1), 1),
			sdPlane(p,vec3(0,1,0),0)),
			sdBox(boxPos, vec3(2,2,2)), 2),
			sdBox(op_twist(p-vec3(-4,2,-4),cos(TIME)), vec3(2,2,2))); 
}

vec3 GetNormal(vec3 p){
	float d = GetDist(p);
	vec2 e = vec2(0.01, 0.0);
	vec3 n = d - vec3(
		GetDist(p-e.xyy),
		GetDist(p-e.yxy),
		GetDist(p-e.yyx));
	return normalize(n);
}

float RayMarch(vec3 ro, vec3 rd){
	float d=0.0; // d = current distance
	for(int i=0; i<MAX_STEPS; i++){
		vec3 p = ro + rd*d; // step along ray
		float dS = GetDist(p);
		d += dS;
		if(d > MAX_DIST || dS<SURF_DIST) break;
	}
	return d;
}

float softshadow( in vec3 ro, in vec3 rd, float mint, float maxt, float w )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<256 && t<maxt; i++ )
    {
        float h = RayMarch(ro + rd*t, rd);
        res = min( res, h/(w*t) );
        t += clamp(h, 0.005, 0.50);
        if( res<-1.0 || t>maxt ) break;
    }
    res = max(res,-1.0);
    return 0.25*(1.0+res)*(1.0+res)*(2.0-res);
}

float hardshadow(in vec3 ro, in vec3 rd, float mint, float maxt, float epsilon) {
    float t = mint;
    for (int i = 0; i < 256 && t < maxt; i++) {
        float h = RayMarch(ro + rd * t, rd);
        if (h < epsilon) {
            return 0.0; // Shadowed
        }
        t += h;
    }
    return 1.0; // Not shadowed
}

void fragment() {
	
	vec3 ws_pixel_pos = ((INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
	vec3 ro = CAMERA_POSITION_WORLD;
	vec3 rd = normalize(ws_pixel_pos - ro);
	
	float d = RayMarch(ro, rd);
	
	//vec3 n = GetNormal(ro + rd * d);
	//vec3 lightDir = normalize(vec3(-3,3,3) - (ro + rd * d));
	//float shadow = softshadow(ro + rd * d, lightDir, 0.01, 30.0, 0.1);
	// Lambertian shading
	//float diffuse = max(dot(n, lightDir), 0.0);
	//ALBEDO = vec3(diffuse) * shadow; //shadow
	
	vec3 n = GetNormal(ro + rd * d);
	ALBEDO = n;
}