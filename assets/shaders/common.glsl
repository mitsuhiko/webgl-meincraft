#ifndef COMMON_GLSL_INCLUDED
#define COMMON_GLSL_INCLUDED

precision highp float;

#ifdef VERTEX_SHADER
attribute vec3 aVertexPosition;
attribute vec3 aVertexNormal;
attribute vec2 aTextureCoord;
#endif
uniform mat4 uModelMatrix;
uniform mat4 uViewMatrix;
uniform mat3 uNormalMatrix;
uniform mat4 uModelViewMatrix;
uniform mat4 uProjectionMatrix;
uniform mat4 uModelViewProjectionMatrix;
uniform vec2 uViewportSize;

uniform sampler2D uTexture;

#endif
