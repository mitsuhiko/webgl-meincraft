#include "common.glsl"
#include "lighting.glsl"
#include "fog.glsl"
uniform vec3 uSunDirection;
uniform vec4 uFogColor;
uniform float uFogDensity;
uniform vec4 uSunColor;
varying vec3 vNormal;
varying vec2 vTextureCoord;
varying vec3 vHalfVec;
varying vec3 vSunDirection;
varying float vFogFactor;

#ifdef VERTEX_SHADER
void main(void)
{
    gl_Position = uModelViewProjectionMatrix * vec4(aVertexPosition, 1.0);
    vTextureCoord = aTextureCoord;
    vSunDirection = uSunDirection;
    vNormal = uNormalMatrix * aVertexNormal;
    vHalfVec = normalize(aVertexPosition + vSunDirection);
    vFogFactor = getFogFactor(uFogDensity);
}
#endif

#ifdef FRAGMENT_SHADER
void main(void)
{
    vec4 darkness = vec4(0.1, 0.1, 0.1, 1.0);
    vec4 ambient = vec4(0.4, 0.4, 0.4, 1.0);
    vec4 diffuse = vec4(0.0);
    vec4 specular = vec4(0.0);
    vec4 color = texture2D(uTexture, vec2(vTextureCoord.s, vTextureCoord.t));

    vec4 sunColor = uSunColor;
    sunColor.a = 0.3;
    directionalLight(vNormal, vSunDirection, vHalfVec,
                     30.0, sunColor, vec4(0.0), diffuse, specular);

    color = color * clamp(darkness + ambient + diffuse, 0.0, 1.0);
    color = mix(uFogColor, color, vFogFactor);
    gl_FragColor = clamp(color, 0.0, 1.0);
}
#endif
