#include "common.glsl"
#include "fxaa.glsl"

#ifdef VERTEX_SHADER
void main(void)
{
    gl_Position = vec4(aVertexPosition, 1.0);
}
#endif

#ifdef FRAGMENT_SHADER
void main(void)
{
    gl_FragColor = applyFXAA(gl_FragCoord.xy, uTexture);
}
#endif
