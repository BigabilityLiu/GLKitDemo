
uniform highp mat4 u_ModelViewMatrix;
uniform highp mat4 u_ProjectionMatrix;

attribute vec4 Position;
attribute vec4 SourceColor;

varying vec4 DestinationColor;


void main(void) {
    DestinationColor = SourceColor;
    gl_Position = u_ProjectionMatrix * u_ModelViewMatrix * Position;
    gl_PointSize = 10.0;
}
