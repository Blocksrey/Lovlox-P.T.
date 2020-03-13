//love_Canvases[layer]
//VaryingColor		 = vec4 Color
//MainTex			 = Image Texture
//VaryingTexCoord	 = vec2 TexturePosition
//love_PixelCoord	 = vec2 PixelPosition

uniform vec2 screendim;
uniform mat4 frusT;
uniform mat4 vertT;

//varying vec3 lightorig;
//varying vec3 lightpixel;
uniform vec3 lightcolor;

uniform vec3 lightdir;

uniform Image wverts;
uniform Image wnorms;
uniform Image colors;
uniform float shadow;

float pi = 3.14159265359;

float pointlightbrightness(float r, vec3 l, vec3 n){
	float d = length(l);
	float c = max(0.0, dot(l, n));
	float s = max(0.0, r - d);//attenuation
	return c*s/(r*d*d*d);
}

float conemax    = 1.0;
float conemin    = 1.0/64.0;
float conefreq   = 4.5;
float conedomain = pi/4.0;
float conerange  = 0.2;

float conedesignfunc(float theta) {
	return (1.0 + conerange*cos(conefreq*conefreq*theta*theta))/(1.0 + conerange);
}

float conebrightinterp(float theta) {
	return (1.0 + cos(pi*theta/conedomain))/2.0;
}

float conebrightnessanglefunc(float theta) {
	theta = clamp(theta, -conedomain, conedomain);
	return conemin + (conemax - conemin)*conedesignfunc(theta)*conebrightinterp(theta);
}

float conelightbrightness(vec3 d, vec3 o, vec3 n) {
	vec3 u = normalize(o);
	float l = length(o);
	float i = -dot(u, n)*0.00001 + 1;//incidence
	float t = acos(dot(d, u));
	return conebrightnessanglefunc(i*t)/(l*l);
}

vec2 getcoord(vec3 pos){
	vec4 fvert = frusT*vec4(pos, 1.0);
	return fvert.xy/(2.0*fvert.w) + vec2(0.5, 0.5);
}

float getdepth(vec3 pos){
	vec4 fvert = frusT*vec4(pos, 1.0);
	return fvert.w;
}

vec4 getpos(vec2 coord){
	//vec2 pixelcoord = screendim*coord;
	//float roundx = (int(pixelcoord.x) + 0.5)/screendim.x;
	//float roundy = (int(pixelcoord.y) + 0.5)/screendim.y;
	//return Texel(wverts, vec2(roundx, roundy));
	return Texel(wverts, coord);
}

float screenraycast(float n, vec3 a, vec3 b){
	for(float i = 0; i < n - 1; i++){
		float t = i/n;
		vec3 p = (1.0 - t)*a + t*b;
		vec2 coord = getcoord(p);
		float pdepth = getdepth(p);
		if(
			0.01 < pdepth &&
			0.0 < coord.x && coord.x < 1.0 &&
			0.0 < coord.y && coord.y < 1.0
		){
			vec4 pixelpos = getpos(coord);
			float gdepth = getdepth(pixelpos.xyz);
			bool isvalid = pixelpos.w != 0.0;
			if(isvalid && gdepth < pdepth - 0.01){
				return 0.0;
			}
		}else{
			break;
		}
	}
	return 1.0;
}

void effect(){
	vec2 coords = love_PixelCoord/screendim;

	vec4 color4 = Texel(colors, coords);

	vec3 wvert = Texel(wverts, coords).xyz;
	vec3 wnorm = Texel(wnorms, coords).xyz;
	vec3 color = color4.rgb;
	float drawn = color4.a;

	if(drawn == 0.0){
		love_Canvases[0] = vec4(0.0, 0.0, 0.0, 1.0);
	}else{
		vec3 diff = wvert - vertT[3].xyz;
		float brightness = conelightbrightness(lightdir, diff, wnorm);

		//float brightness = pointlightbrightness(vertT[0].x, vertT[3].xyz - wvert, wnorm);

		float visible = screenraycast(64.0*shadow, wvert, vertT[3].xyz);

		//love_Canvases[0] = vec4(visible*brightness*lightcolor*color, 1.0);
		love_Canvases[0] = vec4(visible*brightness*lightcolor*color, 1.0);
	}
}