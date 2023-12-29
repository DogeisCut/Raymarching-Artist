shader_type spatial;
render_mode unshaded, depth_test_disabled;

uniform int MAX_STEPS = 100;
uniform float MAX_DIST = 100.0;
uniform float SURF_DIST = 0.001;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;

#include "res://sdfs.gdshaderinc"
#include "res://booleans.gdshaderinc"
#include "res://operations.gdshaderinc"

// **** The Scene SDF ****

float getDist(vec3 position) {
	//vec3 torusPosition = position;
	//torusPosition.yz *= opRotate(TIME);
	//torusPosition.xz *= opRotate(TIME*1.363232);
	//torusPosition.y -= TIME*10.0;
	//boxPosition = opTwist(boxPosition, 0.25);
	//return sdTorus(opRepeat(torusPosition, vec3(5,5,5))-vec3(0,0,0), vec2(1,0.5));
	
	vec3 boxPosition = position - vec3(5,2,5);
	boxPosition.xz *= opRotate(TIME);
	
	return union(
		smoothUnion(
			union(
				smoothUnion(sdSphere(position - vec3(0,1,0), 1), sdSphere(position - vec3(1,2,1), 1), 1),
				sdPlane(position, vec3(0,1,0), 0)
			),
			sdBox(boxPosition, vec3(2,2,2)),
			2
		),
		sdBox(opTwist(position - vec3(-4,2,-4), cos(TIME)), vec3(2,2,2))
	);
}

vec3 getNormal(vec3 point){
	float distanceToPoint = getDist(point);
	vec2 epsilon  = vec2(SURF_DIST, 0.0);
	
	vec3 normal = distanceToPoint - vec3(
		getDist(point-epsilon.xyy),
		getDist(point-epsilon.yxy),
		getDist(point-epsilon.yyx));
	return normalize(normal);
}

float rayMarch(vec3 rayOrigin, vec3 rayDirection) {
	float distanceTravelled = 0.0; // distanceTravelled = current distance
	
	for(int step = 0; step < MAX_STEPS; step++) {
		vec3 currentPoint = rayOrigin + rayDirection * distanceTravelled; // step along ray
		float distanceToSurface = getDist(currentPoint) * 0.5;
		distanceTravelled += distanceToSurface;
		
		if(distanceTravelled > MAX_DIST || distanceToSurface < SURF_DIST)
			break;
	}
	
	return distanceTravelled;
}

// **** Shading Functions ****

float softShadow(in vec3 rayOrigin, in vec3 rayDirection, float minDistance, float maxDistance, float width) {
	float result = 1.0;
	float distanceTravelled = minDistance;
	
	for (int i = 0; i < 256 && distanceTravelled < maxDistance; i++) {
		float distanceToSurface = rayMarch(rayOrigin + rayDirection * distanceTravelled, rayDirection);
		result = min(result, distanceToSurface / (width * distanceTravelled));
		distanceTravelled += clamp(distanceToSurface, 0.005, 0.50);
		
		if (result < -1.0 || distanceTravelled > maxDistance)
			break;
	}
	
	result = max(result, -1.0);
	return 0.25 * (1.0 + result) * (1.0 + result) * (2.0 - result);
}

float hardShadow(in vec3 rayOrigin, in vec3 rayDirection, float minDistance, float maxDistance, float epsilon) {
	float distanceTravelled = minDistance;

	for (int i = 0; i < 256 && distanceTravelled < maxDistance; i++) {
		float distanceToSurface = rayMarch(rayOrigin + rayDirection * distanceTravelled, rayDirection);
		
		if (distanceToSurface < epsilon) {
			return 0.0; // Shadowed
		}
		
		distanceTravelled += distanceToSurface;
	}
	
	return 1.0; // Not shadowed
}

// **** Fragment ****

void fragment() {
	vec3 worldSpacePixelPosition = ((INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz);
	vec3 cameraPositionWorld = CAMERA_POSITION_WORLD;
	vec3 rayDirection = normalize(worldSpacePixelPosition - cameraPositionWorld);
	
	float dist = rayMarch(cameraPositionWorld, rayDirection);
	
	// vec3 normal = getNormal(cameraPositionWorld + rayDirection * dist);
	// vec3 lightDirection = normalize(vec3(-3,3,3) - (cameraPositionWorld + rayDirection * dist));
	// float shadow = softShadow(cameraPositionWorld + rayDirection * dist, lightDirection, 0.01, 30.0, 0.1);
	// // Lambertian shading
	// float diffuse = max(dot(normal, lightDirection), 0.0);
	// ALBEDO = vec3(diffuse) * shadow; //shadow
	
	vec3 normal = getNormal(cameraPositionWorld + rayDirection * dist);
	ALBEDO = normal;
}