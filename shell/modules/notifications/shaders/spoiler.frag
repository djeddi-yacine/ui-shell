#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float ratio;
    vec4 tint;
};

// Moving value noise over a grid that keeps square cells at any aspect ratio.
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float valueNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void main() {
    vec2 uv = qt_TexCoord0 * vec2(ratio, 1.0) * 12.0 + time * vec2(0.6, 0.3);
    float n = valueNoise(uv);
    // Premultiplied alpha.
    fragColor = tint * smoothstep(0.35, 0.65, n) * qt_Opacity;
}
