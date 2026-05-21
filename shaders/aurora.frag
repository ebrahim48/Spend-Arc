#include <flutter/runtime_effect.glsl>

uniform float uTime;
uniform vec2 uResolution;
uniform vec4 uColor1;
uniform vec4 uColor2;

out vec4 fragColor;

// Smooth noise
float hash(vec2 p) {
    p = fract(p * vec2(234.34, 435.345));
    p += dot(p, p + 34.23);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    for (int i = 0; i < 4; i++) {
        value += amplitude * noise(p * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    return value;
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uResolution;

    float t = uTime * 0.3;

    // Aurora wave
    float wave1 = fbm(vec2(uv.x * 2.0 + t, uv.y * 1.5 + t * 0.5));
    float wave2 = fbm(vec2(uv.x * 1.5 - t * 0.7, uv.y * 2.0 + t * 0.3));

    float aurora = wave1 * wave2;
    aurora = smoothstep(0.2, 0.8, aurora);

    // Vertical gradient mask — aurora appears near top
    float mask = smoothstep(0.0, 0.6, 1.0 - uv.y);
    aurora *= mask;

    vec4 color = mix(uColor1, uColor2, wave1);
    color.a = aurora * 0.6;

    fragColor = color;
}
