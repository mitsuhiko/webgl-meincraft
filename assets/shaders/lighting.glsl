#ifndef LIGHTING_GLSL_INCLUDED
#define LIGHTING_GLSL_INCLUDED

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

#endif
