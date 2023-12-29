shader_type spatial;
render_mode unshaded, depth_test_disabled;

uniform int MAX_STEPS = 100;
uniform float MAX_DIST = 100.0;
uniform float SURF_DIST = 0.001;
uniform vec3 LIGHT_POS = vec3(-3,10,3);
uniform vec3 SUN_DIRECTION = vec3(0.6,1,0.6);

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;

#include "res://global.gdshaderinc"

#include "res://sdfs.gdshaderinc"
#include "res://booleans.gdshaderinc"
#include "res://operations.gdshaderinc"

// **** The Scene SDF ****

Surface sdScene(vec3 position) {
	//vec3 torusPosition = position;
	//torusPosition.yz *= opRotate(TIME);
	//torusPosition.xz *= opRotate(TIME*1.363232);
	//torusPosition.y -= TIME*10.0;
	//boxPosition = opTwist(boxPosition, 0.25);
	//return sdTorus(opRepeat(torusPosition, vec3(5,5,5))-vec3(0,0,0), vec2(1,0.5));
	Surface scene;
	
	
	scene = smoothUnion(Surface(sdSphere(position - vec3(0,1,0), 1),vec3(1,1,1),1.0,0.0),
						Surface(sdSphere(position - vec3(1,2,1), 1), vec3(1,1,1),1.0,0.0),
						1);
	scene = union(scene, Surface(sdPlane(position, vec3(0,1,0), 0), vec3(1,1,1),1.0,0.0));
	
	vec3 boxPosition = position - vec3(5,2,5);
	boxPosition.xz *= opRotate(TIME);
	scene = smoothUnion(scene, Surface(sdBox(boxPosition, vec3(2,2,2)), vec3(1,0,0),1.0,0.0), 2);
	
	scene = union(scene, Surface(sdBox(opTwist(position - vec3(-4,2,-4), cos(TIME)), vec3(2,2,2)), vec3(1,1,1),1.0,0.0));
	
	return scene;
}

vec3 getNormal(vec3 point){
	float distanceToPoint = sdScene(point).signedDistanceValue;
	vec2 epsilon  = vec2(SURF_DIST, 0.0);
	
	vec3 normal = distanceToPoint - vec3(
		sdScene(point-epsilon.xyy).signedDistanceValue,
		sdScene(point-epsilon.yxy).signedDistanceValue,
		sdScene(point-epsilon.yyx).signedDistanceValue);
	return normalize(normal);
}

float rayMarch(vec3 rayOrigin, vec3 rayDirection) {
	float distanceTravelled = 0.0; // distanceTravelled = current distance
	
	for(int step = 0; step < MAX_STEPS; step++) {
		vec3 currentPoint = rayOrigin + rayDirection * distanceTravelled; // step along ray
		float distanceToSurface = sdScene(currentPoint).signedDistanceValue * 0.5;
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
	
	// normal light
	//float dist = rayMarch(cameraPositionWorld, rayDirection);
	//
	 //vec3 normal = getNormal(cameraPositionWorld + rayDirection * dist);
	 //vec3 lightDirection = normalize(LIGHT_POS - (cameraPositionWorld + rayDirection * dist));
	 //float shadow = hardShadow(cameraPositionWorld + rayDirection * dist, lightDirection, 0.01, 30.0, 0.1);
	 //// Lambertian shading
	 //float diffuse = max(dot(normal, lightDirection), 0.0);
	 //ALBEDO = vec3(diffuse) * shadow; //shadow
	
	//sun lighting
	float dist = rayMarch(cameraPositionWorld, rayDirection);
	if (dist > MAX_DIST) {
		ALBEDO = vec3(0.835,1,1);
	} else {
		vec3 normal = getNormal(cameraPositionWorld + rayDirection * dist);
		vec3 lightDirection = normalize(SUN_DIRECTION);
		float shadow = hardShadow(cameraPositionWorld + rayDirection * dist, lightDirection, 0.01, 30.0, 0.1);
		float diffuse = max(dot(normal, lightDirection), 0.0);
		ALBEDO = vec3(diffuse) * shadow; //shadow
		ALBEDO = mix(ALBEDO, vec3(0.835,1,1), dist/MAX_DIST); //ez fog lol
	}
	
	
	//vec3 normal = getNormal(cameraPositionWorld + rayDirection * dist);
	//ALBEDO = normal;
}