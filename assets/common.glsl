#ifdef VERTEX_SHADER
attribute vec3 aVertexPosition;
attribute vec3 aVertexNormal;
attribute vec2 aTextureCoord;
uniform mat4 uModelViewMatrix;
uniform mat4 uProjectionMatrix;
#endif

uniform sampler2D uTexture;
