#include "common.glsl"
varying highp vec2 vTextureCoord;

#ifdef VERTEX_SHADER
void main(void)
{
    gl_Position = uModelViewProjectionMatrix * vec4(aVertexPosition, 1.0);
    vTextureCoord = aTextureCoord;
}
#endif

#ifdef FRAGMENT_SHADER
void main(void)
{
    gl_FragColor = texture2D(uTexture, vec2(vTextureCoord.s, vTextureCoord.t));
}
#endif
