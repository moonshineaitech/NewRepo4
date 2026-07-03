#include <metal_stdlib>
using namespace metal;

// A slow diagonal glint that sweeps across the metal, as if the instrument
// were catching gallery lighting. Applied via SwiftUI's colorEffect.
[[ stitchable ]] half4 goldShimmer(float2 position, half4 color, float time, float2 size) {
    if (color.a < 0.003h) {
        return color;
    }

    float extent = max(size.x, 1.0);
    float2 uv = position / extent;

    // Primary sweeping band.
    float band = sin((uv.x + uv.y) * 5.5 - time * 1.35);
    float glint = smoothstep(0.86, 1.0, band);

    // A faint counter-sweep so the surface never looks static.
    float counter = sin((uv.x - uv.y) * 8.0 + time * 0.6);
    float microGlint = smoothstep(0.94, 1.0, counter);

    half boost = half(glint) * 0.30h + half(microGlint) * 0.12h;
    half3 lifted = min(color.rgb + half3(boost, boost, boost * 0.72h), half3(1.0h));
    return half4(lifted, color.a);
}
