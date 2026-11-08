// Optional, single-pass cursor echo for Ghostty 1.4 cursor uniforms.
// Original texture/cursor remain intact. A short, low-alpha shaped echo moves
// toward the actual cursor for 110 ms. No glow, particles, or input changes.
// Disabled by default: custom-shader-animation=true renders continuously
// while focused; Ghostty 1.4 has no bounded animation scheduling option.
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    fragColor = texture(iChannel0, uv);
    float age = iTime - iTimeCursorChange;
    if (iFocus == 0 || iCursorVisible.x < 0.5 || age < 0.0 || age >= 0.11)
        return;
    if (iCurrentCursorStyle.x != iPreviousCursorStyle.x || iCurrentCursorStyle.x == 4.0)
        return;
    vec2 size = iCurrentCursor.zw;
    vec2 now = iCurrentCursor.xy + size * vec2(0.5, -0.5);
    vec2 old = iPreviousCursor.xy + iPreviousCursor.zw * vec2(0.5, -0.5);
    float distanceMoved = length(now - old);
    if (distanceMoved < 1.0 || distanceMoved > 12.0 * max(size.x, size.y))
        return;
    float t = clamp(age / 0.11, 0.0, 1.0);
    float ease = 1.0 - pow(1.0 - t, 3.0);
    vec2 center = mix(old, now, ease);
    vec2 q = abs(fragCoord - center) - max(size * 0.5, vec2(0.5));
    float edge = max(q.x, q.y);
    float mask = 1.0 - smoothstep(-0.5, 0.5, edge);
    if (iCurrentCursorStyle.x == 1.0) {
        vec2 inner = abs(fragCoord - center) - max(size * 0.5 - 1.5, vec2(0.0));
        mask *= smoothstep(-0.5, 0.5, max(inner.x, inner.y));
    }
    fragColor.rgb = mix(fragColor.rgb, iCurrentCursorColor.rgb,
                        mask * 0.14 * (1.0 - t) * iCurrentCursorColor.a);
}
