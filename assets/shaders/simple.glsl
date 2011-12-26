#include "common.glsl"
varying vec3 vNormal;
varying vec2 vTextureCoord;
varying vec3 vHalfVec;
varying vec3 vSunDirection;

#ifdef VERTEX_SHADER
void main(void)
{
    gl_Position = uModelViewProjectionMatrix * vec4(aVertexPosition, 1.0);
    vTextureCoord = aTextureCoord;
    vSunDirection = normalize(vec3(0.7, 0.8, 1.0));
    vNormal = uNormalMatrix * aVertexNormal;
    vHalfVec = normalize(aVertexPosition + vSunDirection);
}
#endif

#ifdef FRAGMENT_SHADER
void directionalLight(in vec3 normal,
                      in vec3 lightDir,
                      in vec3 halfVec,
                      in float shininess,
                      in vec4 lightDiffuse,
                      in vec4 lightSpecular,
                      inout vec4 diffuse,
                      inout vec4 specular)
{
    float nDotVp;   /* normal . light dir */
    float nDotHv;   /* normal . half vec */
    float pf;       /* power factor */

    nDotVp = max(0.0, dot(normal, normalize(lightDir)));
    nDotHv = max(0.0, dot(normal, halfVec));
    pf = (nDotVp == 0.0) ? 0.0 : pow(nDotHv, shininess);

    diffuse += lightDiffuse * nDotVp;
    specular += lightSpecular * pf;
}

void main(void)
{
    vec4 darkness = vec4(0.1, 0.1, 0.1, 1.0);
    vec4 ambient = vec4(0.4, 0.4, 0.4, 1.0);
    vec4 diffuse = vec4(0.0);
    vec4 specular = vec4(0.0);
    vec4 color = texture2D(uTexture, vec2(vTextureCoord.s, vTextureCoord.t));

    directionalLight(vNormal, vSunDirection, vHalfVec,
                     30.0, vec4(1.0, 1.0, 1.0, 0.3), vec4(0.0),
                     diffuse, specular);

    color = color * clamp(darkness + ambient + diffuse, 0.0, 1.0);
    gl_FragColor = clamp(color, 0.0, 1.0);
}
#endif
