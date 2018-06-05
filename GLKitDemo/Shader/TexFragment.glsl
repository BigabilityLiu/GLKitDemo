
uniform sampler2D u_Texture1;
uniform sampler2D u_Texture2;

varying lowp vec4 frag_Color;
varying lowp vec2 frag_TexCoord;

void main(void) {
    gl_FragColor = frag_Color * mix(texture2D(u_Texture1, vec2(1.0 - frag_TexCoord.x, frag_TexCoord.y)), texture2D(u_Texture2, frag_TexCoord), 0.0);
}
