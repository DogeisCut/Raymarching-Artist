shader_type spatial;
render_mode unshaded;

uniform int MAX_STEPS = 100;
uniform float MAX_DIST = 100.0;
uniform float SURF_DIST = 0.001;
uniform vec3 LIGHT_POS = vec3(-3,10,3);
uniform vec3 SUN_DIRECTION = vec3(-0.5,1,0.6);
uniform float AO_APPLIES_FROM: hint_range(-1.0, 1.0) = 0.5;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;

#include "res://src/shaders/global.gdshaderinc"

#include "res://src/shaders/sdfs.gdshaderinc"
#include "res://src/shaders/booleans.gdshaderinc"
#include "res://src/shaders/operations.gdshaderinc"

// **** The Scene SDF ****

Surface sdScene(vec3 position) {
	//vec3 torusPosition = position;
	//torusPosition.yz *= opRotate(TIME);
	//torusPosition.xz *= opRotate(TIME*1.363232);
	//torusPosition.y -= TIME*10.0;
	//boxPosition = opTwist(boxPosition, 0.25);
	//return sdTorus(opRepeat(torusPosition, vec3(5,5,5))-vec3(0,0,0), vec2(1,0.5));
	Surface scene;
	
	
	scene = smoothUnion(
		new_surface(sdSphere(position - vec3(0,1,0), 1), vec3(0,1,0),1.0,0.0,0.0),
		new_surface(sdSphere(position - vec3(1,2,1), 1), vec3(0,0,1),1.0,0.0,0.0),
		1
	);
	
	vec3 floorColor = vec3(1. + 0.7*mod(floor(position.x) + floor(position.z), 2.0));
	scene = union(scene, new_surface(sdPlane(position, vec3(0,1,0), 0), floorColor,1.0,0.0,0.0));
	
	vec3 boxPosition = position - vec3(5,2,5);
	boxPosition.xz *= opRotate(TIME);
	scene = smoothUnion(scene, new_surface(sdBox(boxPosition, vec3(2,2,2)), vec3(1,0,0),1.0,0.0,0.0), 2);
	
	scene = union(scene, new_surface(sdBox(opTwist(position - vec3(-4,2,-4), cos(TIME)), vec3(2,2,2)), vec3(1,0,1),1.0,0.0,0.0));
	
	scene = paint(new_surface(sdBox(position - vec3(-4.5,1,4.5), vec3(2,2,2)), vec3(1,0.5,0),1.0,0.0,0.0), scene);
	
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

Surface rayMarch(vec3 rayOrigin, vec3 rayDirection) {
	float distanceTravelled = 0.0; // distanceTravelled = current distance
	Surface closestObject;
	
	int step = 0;
	for(; step < MAX_STEPS; step++) {
		vec3 currentPoint = rayOrigin + rayDirection * distanceTravelled; // step along ray
		closestObject = sdScene(currentPoint);
		distanceTravelled += closestObject.signedDistanceValue * 0.5;
		if(distanceTravelled > MAX_DIST || closestObject.signedDistanceValue < SURF_DIST) break;
	}
	
	closestObject.signedDistanceValue = distanceTravelled;
	closestObject.marches = step;
	
	return closestObject;
}

// **** Shading Functions ****

float softShadow(in vec3 rayOrigin, in vec3 rayDirection, float minDistance, float maxDistance, float width) {
	float result = 1.0;
	float distanceTravelled = minDistance;
	
	for (int i = 0; i < 256 && distanceTravelled < maxDistance; i++) {
		float distanceToSurface = rayMarch(rayOrigin + rayDirection * distanceTravelled, rayDirection).signedDistanceValue;
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
		float distanceToSurface = rayMarch(rayOrigin + rayDirection * distanceTravelled, rayDirection).signedDistanceValue;
		
		if (distanceToSurface < epsilon) {
			return 0.0; // Shadowed
		}
		
		distanceTravelled += distanceToSurface;
	}
	
	return 1.0; // Not shadowed
}

float ambientOcclusion(int marches) {
	float F_MAX_STEPS = float(MAX_STEPS);
	float STEP_FRACT = F_MAX_STEPS * AO_APPLIES_FROM;
	return clamp(
		1.0 - (
			(
				clamp(
					float(marches),
					STEP_FRACT,
					F_MAX_STEPS
				) - STEP_FRACT
			) / F_MAX_STEPS
		),
		0.0,
		1.0
	);
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
	Surface dist = rayMarch(cameraPositionWorld, rayDirection);
	if (dist.signedDistanceValue > MAX_DIST) {
		ALBEDO = vec3(0.835,1,1);
	} else {
		vec3 normal = getNormal(cameraPositionWorld + rayDirection * dist.signedDistanceValue);
		vec3 lightDirection = normalize(SUN_DIRECTION);
		float shadow = hardShadow(cameraPositionWorld + rayDirection * dist.signedDistanceValue, lightDirection, 0.01, 30.0, 0.1);
		float diffuse = max(dot(normal, lightDirection), 0.0);
		ALBEDO = vec3(diffuse*dist.color) * shadow * ambientOcclusion(dist.marches); //shadow
		ALBEDO = mix(ALBEDO, vec3(0.835,1,1), dist.signedDistanceValue/MAX_DIST); //ez fog lol
	}
	
	
	//vec3 normal = getNormal(cameraPositionWorld + rayDirection * dist);
	//ALBEDO = normal;
}