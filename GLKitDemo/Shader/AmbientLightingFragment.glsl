struct Light {
    lowp vec3 Color;
    lomp float AmbientIntensity;
};
uniform Light u_Light;

void main(void) { // 2
    lowp vec4 AmbientColor = vec4(u_Light.Color, 1.0) * u_Light.AmbientIntensity;
    gl_FragColor = texture2D(u_Texture, frag_TexCoord) * (AmbientColor)
}
