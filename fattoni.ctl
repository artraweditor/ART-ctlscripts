// @ART-label: "$CTL_FATTONI_SPLIT_TONING;FatToni - Split Toning"
// @ART-param: ["highlight_hue", "$CTL_HIGHLIGHT_HUE;Highlight hue", 0.0, 360.0, 0.0, 1.0]
// @ART-param: ["highlight_sat", "$CTL_HIGHLIGHT_SATURATION;Highlight saturation", 0.0, 100.0, 0.0, 1.0]
// @ART-param: ["shadow_hue", "$CTL_SHADOW_HUE;Shadow hue", 0.0, 360.0, 0.0, 1.0]
// @ART-param: ["shadow_sat", "$CTL_SHADOW_SATURATION;Shadow saturation", 0.0, 100.0, 0.0, 1.0]
// @ART-param: ["separation", "$CTL_SEPARATION_MIX;Separation (mix)", 0.0, 100.0, 0.0, 1.0]
// @ART-param: ["mids", "$CTL_MIDPOINT;Midpoint", -100.0, 100.0, 0.0, 1.0]
// @ART-param: ["contrast", "$CTL_CONTRAST;Contrast", -100.0, 1000.0, 85.0, 1.0]
// @ART-param: ["base_hue", "$CTL_BASE_HUE;Base hue", 0.0, 360.0, 0.0, 1.0]
// @ART-param: ["base_sat", "$CTL_BASE_SATURATION;Base saturation", 0.0, 100.0, 0.0, 1.0]
// @ART-param: ["base_luma", "$CTL_BASE_LUMINANCE;Base luminance", 0.0, 100.0, 100.0, 1.0]
// @ART-colorspace: "rec2020"

// Port to ART (C) Spoilerhead 2026
// based on https://github.com/spoilerhead/asp_plugins/
// license: GPL-2.0-or-later,
// V1.01

float ft_clip(float x, float lo, float hi)
{
    if (x < lo) return lo;
    if (x > hi) return hi;
    return x;
}

float ft_fastsin(float x)
{
    float y = x;
    float pi = 3.14159265358979323846;
    if (y < -pi) y = y + 2.0 * pi;
    else if (y > pi) y = y - 2.0 * pi;
    if (y < 0.0) return (1.27323954 + 0.405284735 * y) * y;
    return (1.27323954 - 0.405284735 * y) * y;
}

float ft_hue2rgb(float p, float q, float t)
{
    float tt = t;
    if (tt < 0.0) tt = tt + 1.0;
    if (tt > 1.0) tt = tt - 1.0;
    if (tt < 1.0 / 6.0) return p + (q - p) * 6.0 * tt;
    if (tt < 1.0 / 2.0) return q;
    if (tt < 2.0 / 3.0) return p + (q - p) * (2.0 / 3.0 - tt) * 6.0;
    return p;
}

float ft_hsl_channel(float h, float s, float l, float offset)
{
    float q;
    float p;
    if (l <= 0.000001) return 0.0;
    if (s <= 0.000001) return l;
    if (l <= 0.5) q = l * (1.0 + s);
    else q = l + s - l * s;
    p = 2.0 * l - q;
    return ft_hue2rgb(p, q, h + offset);
}

float ft_screen(float f, float b)
{
    return 1.0 - (1.0 - f) * (1.0 - b);
}

float ft_overlay(float f, float b)
{
    return b * ft_screen(f, b) + (1.0 - b) * (f * b);
}

float ft_blend(float f, float b, float o)
{
    return f * o + b * (1.0 - o);
}

float ft_softmix(float f, float b)
{
    return b + f - 0.5;
}

void ART_main(varying float r, varying float g, varying float b,
              output varying float r_out, output varying float g_out, output varying float b_out,
              float highlight_hue, float highlight_sat,
              float shadow_hue, float shadow_sat,
              float separation, float mids, float contrast,
              float base_hue, float base_sat, float base_luma)
{
    /*
     * Encode into the gamma-adjusted working domain.
     *
     * gamma = 1.0 -> no gamma transformation
     * gamma = 2.2 -> x^(1/2.2)
     * gamma = 5.0 -> x^(1/5.0)
     */
	float gamma = 2.2;
    float inv_gamma = 1.0 / gamma;

    float rr = pow(ft_clip(r, 0.0, 1.0), inv_gamma);
    float gg = pow(ft_clip(g, 0.0, 1.0), inv_gamma);
    float bb = pow(ft_clip(b, 0.0, 1.0), inv_gamma);

    float hh = highlight_hue / 360.0;
    float hs = highlight_sat / 100.0;
    float sh = shadow_hue / 360.0;
    float ss = shadow_sat / 100.0;
    float bh = base_hue / 360.0;
    float bs = base_sat / 100.0;
    float bl = base_luma / 100.0;

    float hr = ft_hsl_channel(hh, hs, 0.5, 1.0 / 3.0);
    float hg = ft_hsl_channel(hh, hs, 0.5, 0.0);
    float hb = ft_hsl_channel(hh, hs, 0.5, -1.0 / 3.0);
    float sr = ft_hsl_channel(sh, ss, 0.5, 1.0 / 3.0);
    float sg = ft_hsl_channel(sh, ss, 0.5, 0.0);
    float sb = ft_hsl_channel(sh, ss, 0.5, -1.0 / 3.0);
    float br = ft_hsl_channel(bh, bs, bl, 1.0 / 3.0);
    float bg = ft_hsl_channel(bh, bs, bl, 0.0);
    float bz = ft_hsl_channel(bh, bs, bl, -1.0 / 3.0);

    float luma = (rr + gg + bb) / 3.0;
    float a = ft_clip(luma + mids / 200.0, 0.0, 1.0);
    a = ft_clip(a - (0.5 * separation / 100.0) * ft_fastsin(2.0 * 3.14159265358979323846 * a), 0.0, 1.0);

    float tr = ft_blend(hr, sr, a);
    float tg = ft_blend(hg, sg, a);
    float tb = ft_blend(hb, sb, a);
    float c = contrast / 100.0;

    rr = ft_blend(ft_overlay(tr, rr), ft_clip(ft_softmix(tr, rr), 0.0, 1.0), c);
    gg = ft_blend(ft_overlay(tg, gg), ft_clip(ft_softmix(tg, gg), 0.0, 1.0), c);
    bb = ft_blend(ft_overlay(tb, bb), ft_clip(ft_softmix(tb, bb), 0.0, 1.0), c);

    rr = ft_clip(br * rr, 0.0, 1.0);
    gg = ft_clip(bg * gg, 0.0, 1.0);
    bb = ft_clip(bz * bb, 0.0, 1.0);

    /*
     * Undo the gamma transform before returning to ART.
     */
    r_out = pow(rr, gamma);
    g_out = pow(gg, gamma);
    b_out = pow(bb, gamma);
}
