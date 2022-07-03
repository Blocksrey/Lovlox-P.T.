varying vec4 fragcoord;

void position(mat4 I, vec4 vert) {
	fragcoord = I*vert;
}