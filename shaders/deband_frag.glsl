//THIS IS THE FINAL PASS
//THIS RENDERS TO THE SCREEN
//WE USE Y-INVERTED COORDINATES

uniform Image finalcanvas;
uniform vec2 screendim;

uniform Image randomimage;
uniform vec2 randomsize;
uniform vec2 randomoffset;

uniform mat4 frusT;

varying vec4 fragcoord;

vec4 rand(vec2 xy){
	vec2 unitcoord = (xy + randomoffset)/randomsize;
	return Texel(randomimage, mod(unitcoord, 1.0));
}

//Just an equation I found on the internet
vec3 filmicToneMapping(vec3 color){
	color = max(vec3(0.0), color - vec3(0.004));
	color = (color * (6.2 * color + 0.5)) / (color * (6.2 * color + 1.7) + 0.06);
	return color;
}





vec3 getbasecolor(vec2 coord) {
	vec2 coords = coord/screendim;
	coords = vec2(coords.x, 1.0 - coords.y);
	vec3 basecolor = Texel(finalcanvas, coords).rgb;
	return basecolor;
}





//deband "module"
const float debandcoef = 1.0/256.0;

vec3 getdeband(vec2 fragcoord) {
	return debandcoef*rand(fragcoord).rgb + debandcoef/2.0;
}




//WHAT THE FUCK
/*
//chromatic aberration "module"
const int chromaiter  = 4;
const float chromalen = 32.0;

vec3 calcchroma(vec2 coord) {
	vec2 texcoord = coord/screendim;
	vec2 centoff = 1.0 - 2.0*texcoord;

	vec2 blend = chromalen*centoff;

	vec3 basecolor = getbasecolor(love_PixelCoord);
	basecolor.r = getbasecolor(love_PixelCoord - 32*centoff).r;

	vec3 sum = vec3(0, 0, 0);
	for (int i = 0; i < chromaiter; ++i) {
		float mul = i/(chromaiter - 1);
		vec2 curtex = texcoord + mul*centoff;
		vec2 curfrag = screendim*curtex;
		sum += getbasecolor(curfrag);
		//vec2 texcoord = 1 - 2*
		//vec2 coord = 0.5*(othercentoff - 1.0)*screendim;

		//sum += getbasecolor(love_PixelCoord);
	}
	
	return sum;
}
*/










//chromatic aberration "module"
const int chromaiter  = 8;
const float chromalen = 1.0/128.0;
const vec3 chromabias = vec3(1, 0, 0);

vec3 calcchroma(vec2 fragcoord) {
	vec2 texcoord = fragcoord/screendim;
	vec2 centoff = 1.0 - 2.0*texcoord;

	vec3 sum = getbasecolor(fragcoord);
	for (int i = 0; i < chromaiter; ++i) {
		float mul = chromalen*i/(chromaiter - 1);
		vec2 curtex = texcoord + mul*centoff;
		vec2 curfrag = screendim*curtex;
		sum += getbasecolor(curfrag);
	}

	vec3 final = getbasecolor(fragcoord)*chromabias + (1 - chromabias)*sum/chromaiter;

	return final;
}





//grain "module"
const float grainfrequency = 512.0;
const float graincoef      = 1.0/24.0;

vec3 calcgrain(vec2 fragcoord) {
	vec2 scalecoord = fragcoord/screendim.y;
	return graincoef*rand(grainfrequency*scalecoord).rgb;
}




void effect() {
	vec3 basecolor   = calcchroma(love_PixelCoord);
	vec3 mappedcolor = filmicToneMapping(basecolor);
	vec3 noise       = getdeband(love_PixelCoord);
	vec3 grain       = calcgrain(love_PixelCoord);
	vec3 finalcolor  = mappedcolor + noise + grain;
	love_Canvases[0] = vec4(finalcolor - mod(finalcolor, debandcoef), 1.0);//write to screen
}