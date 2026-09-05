// dissolve.frag
// Text particle dissolve — adapted from example-0 for Flutter FragmentProgram.
//
// Uniforms (setFloat order):
//   0  uSize.x   — canvas width  (px)
//   1  uSize.y   — canvas height (px)
//   2  uTime     — elapsed seconds
//   3  uDissolve — global dissolve progress 0→1
// Sampler 0:
//   uText — greyscale ui.Image with white text on black background
//
// Effect:
//   • Canvas is divided into CS×CS cells.  Each cell owns one particle.
//   • Text is sampled at the cell centre to determine if a particle exists.
//   • Per-cell random gives a staggered launch threshold (mirrors Three.js example).
//   • Dot shape within the cell, appear/vanish window, colour shift, sparkle.
//   • Solid text fades out as uDissolve rises, replaced by lit particles.

#include <flutter/runtime_effect.glsl>

uniform vec2      uSize;
uniform float     uTime;
uniform float     uDissolve;
uniform sampler2D uText;

out vec4 fragColor;

float rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
    vec2  fc  = FlutterFragCoord().xy;
    vec2  uv  = fc / uSize;

    // ── Grid cell ──────────────────────────────────────────────────────────
    const float CS = 3.0;                         // cell size in px
    vec2  cell    = floor(fc / CS);
    vec2  cellUV  = (cell * CS + CS * 0.5) / uSize; // cell-centre UV

    float r1 = rand(cell);
    float r2 = rand(cell + vec2(57.3, 83.7));

    // ── Text mask ──────────────────────────────────────────────────────────
    float textCell  = texture(uText, cellUV).r;   // text at particle origin
    float textFrag  = texture(uText, uv).r;        // text at exact fragment
    bool  isText    = textCell > 0.25;

    // ── Per-particle stagger (same formula as Three.js example) ───────────
    float thresh = 0.15 + r1 * 0.70;              // [0.15, 0.85]
    float local  = isText
        ? clamp((uDissolve - thresh) / max(1.0 - thresh, 0.01), 0.0, 1.0)
        : 0.0;

    // ── Dot shape (soft circle inside cell) ───────────────────────────────
    vec2  off  = fract(fc / CS) - 0.5;
    float d    = length(off);
    float dot  = 1.0 - smoothstep(0.22, 0.46, d);

    // ── Particle visibility ────────────────────────────────────────────────
    float appear  = smoothstep(0.0,  0.20, local);
    float vanish  = 1.0 - smoothstep(0.70, 1.0,  local);
    float sparkle = 0.80 + 0.20 * sin(uTime * 5.0 + r2 * 12.0);
    float partA   = isText ? dot * appear * vanish * sparkle : 0.0;

    // ── Solid text (dissolves out as uDissolve rises) ──────────────────────
    float solidA  = textFrag * (1.0 - smoothstep(0.18, 0.48, uDissolve));

    // ── Colour: blue → magenta → gold ─────────────────────────────────────
    vec3 c0 = vec3(0.45, 0.75, 1.00);
    vec3 c1 = vec3(0.95, 0.45, 0.75);
    vec3 c2 = vec3(1.00, 0.85, 0.45);
    vec3 partColor = local < 0.5
        ? mix(c0, c1, local * 2.0)
        : mix(c1, c2, (local - 0.5) * 2.0);
    vec3 solidColor = vec3(0.08, 0.08, 0.08);

    vec3 bg    = vec3(0.95, 0.95, 0.95);
    vec3 color = mix(solidColor, partColor, step(0.01, partA));
    float alpha = max(solidA, partA);

    fragColor = vec4(mix(bg, color, clamp(alpha, 0.0, 1.0)), 1.0);
}
