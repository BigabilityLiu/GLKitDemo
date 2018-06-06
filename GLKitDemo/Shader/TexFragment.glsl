
uniform sampler2D u_Texture1;
uniform sampler2D u_Texture2;

varying lowp vec4 frag_Color;
varying lowp vec2 frag_TexCoord;
varying lowp vec3 frag_Normal;

struct Light {
    lowp vec3 Color;
    lowp float AmbientIntensity;
    lowp float DiffuseIntensity;
    lowp vec3 Direction;
};
uniform Light u_Light;

void main(void) {
    
    lowp vec3 AmbientColor = u_Light.Color * u_Light.AmbientIntensity;
    
    lowp vec3 Normal = normalize(frag_Normal);
    lowp float DiffuseFactor = max(-dot(Normal, u_Light.Direction), 0.0);
    lowp vec3 DiffuseColor = u_Light.Color * u_Light.DiffuseIntensity * DiffuseFactor;
    
    gl_FragColor = frag_Color * mix(texture2D(u_Texture1, vec2(1.0 - frag_TexCoord.x, frag_TexCoord.y)), texture2D(u_Texture2, frag_TexCoord), 0.5) * vec4((AmbientColor + DiffuseColor), 1.0);
}
