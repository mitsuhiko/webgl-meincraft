#ifndef FOG_GLSL_INCLUDED
#define FOG_GLSL_INCLUDED

/* Calculates the fog factor for a fog of the given density and the current
   vertex or fragment position.  This function behaves differently depending
   on if it's excuted from the vertex or fragment shader. */
float getFogFactor(float density)
{
    const float LOG2 = 1.442695;
    float z;
#ifdef VERTEX_SHADER
    z = length(vec3(uModelViewMatrix * vec4(aVertexPosition, 1.0)));
#else
    z = gl_FragCoord.z / gl_FragCoord.w;
#endif
    return clamp(exp2(-density * density * z * z * LOG2), 0.0, 1.0);
}

#endif
