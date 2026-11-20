// @ART-label: "$CTL_SILICONBONK_BW;SiliconBonk - B&W Conversion"
// @ART-param: ["hue", "$CTL_HUE;Hue", 0.0, 360.0, 0.0, 1.0]
// @ART-param: ["luma", "$CTL_LUMINANCE_CHANGE;Luminance change", -100.0, 100.0, 0.0, 1.0]
// @ART-param: ["saturation", "$CTL_SATURATION;Saturation", 0.0, 200.0, 0.0, 1.0]
// @ART-param: ["mids", "$CTL_MIDPOINT;Midpoint", -100.0, 100.0, 0.0, 1.0]
// @ART-param: ["contrast", "$CTL_CONTRAST;Contrast", -100.0, 500.0, 0.0, 1.0]
// @ART-param: ["preserve_details", "$CTL_PRESERVE_HIGHLIGHTS_DETAILS;Preserve highlights/details", false]
// @ART-colorspace: "rec2020"

// Port to ART (C) Spoilerhead 2026
// based on https://github.com/spoilerhead/asp_plugins/
// license: GPL-2.0-or-later,
// V1.01

float sb_clip(float x, float lo, float hi)
{
    if (x < lo) return lo;
    if (x > hi) return hi;
    return x;
}

float sb_min3(float x, float y, float z)
{
    float m = x;
    if (y < m) m = y;
    if (z < m) m = z;
    return m;
}

float sb_max3(float x, float y, float z)
{
    float m = x;
    if (y > m) m = y;
    if (z > m) m = z;
    return m;
}

float sb_fastsin(float x)
{
    float y = x;
    float pi = 3.14159265358979323846;
    if (y < -pi) y = y + 2.0 * pi;
    else if (y > pi) y = y - 2.0 * pi;
    if (y < 0.0) return (1.27323954 + 0.405284735 * y) * y;
    return (1.27323954 - 0.405284735 * y) * y;
}

float sb_fastcos(float x)
{
    return sb_fastsin(x + 3.14159265358979323846 / 2.0);
}

void ART_main(varying float r, varying float g, varying float b,
              output varying float r_out, output varying float g_out, output varying float b_out,
              float hue, float luma, float saturation, float mids, float contrast,
             bool preserve_details)
{

	float gamma = 2.2;
    float inv_gamma = 1.0 / gamma;

    float rr = pow(sb_clip(r, 0.0, 1.0), inv_gamma);
    float gg = pow(sb_clip(g, 0.0, 1.0), inv_gamma);
    float bb = pow(sb_clip(b, 0.0, 1.0), inv_gamma);
	

    float mn = sb_min3(rr, gg, bb);
    float mx = sb_max3(rr, gg, bb);
    float val = 0.299 * rr + 0.587 * gg + 0.114 * bb;
    float sat = 0.0;
    float h = 0.0;

    if (val > 0.000001 && mx - mn > 0.000001) {
        sat = (mx - mn) / val;

        float nr = rr / mx;
        float ng = gg / mx;
        float nb = bb / mx;
        float nmn = sb_min3(nr, ng, nb);
        float nmx = sb_max3(nr, ng, nb);
        float d = nmx - nmn;
        nr = (nr - nmn) / d;
        ng = (ng - nmn) / d;
        nb = (nb - nmn) / d;
        nmx = sb_max3(nr, ng, nb);

        if (nmx == nr) {
            h = (ng - nb) / 6.0;
            if (h < 0.0) h = h + 1.0;
        } else if (nmx == ng) {
            h = 1.0 / 3.0 + (nb - nr) / 6.0;
        } else {
            h = 2.0 / 3.0 + (nr - ng) / 6.0;
        }
    }

    float opt_h = hue / 360.0;
    float alpha = 0.5 * sb_fastcos(
        (h - opt_h) * 2.0 * 3.14159265358979323846
    );

    alpha = alpha * sb_clip(sat * (2.0 - sat), 0.0, 1.0);

    float lmod = 1.0 + 0.5 * (luma / 50.0);
    float val_mod = lmod * val;
    float val_new = val_mod * alpha + val * (1.0 - alpha);

    if (preserve_details) {
        val_new =
            ((-0.4481 * val_new + 0.5489) * val_new + 0.7659)
            * val_new + 0.03891;
    }

    val_new = val_new
            + (mids / 100.0)
            * (val_new - val_new * val_new);

    float c = contrast / 100.0;
    float linear_c = 1.0;

    if (c > 1.0) {
        linear_c = 1.0 + 2.0 * (c - 1.0) * (c - 1.0);
        c = 1.0;
    }

    val_new = sb_clip(val_new, 0.0, 1.0);

    val_new = val_new
            - (c / 4.4)
            * sb_fastsin(
                2.0 * 3.14159265358979323846 * val_new
              );

    val_new = (val_new - 0.5) * linear_c + 0.5;

    val = sb_clip(val_new, 0.0, 1.0);
    sat = sat * (saturation / 100.0);

    if (val <= 0.000001) {
        rr = 0.0;
        gg = 0.0;
        bb = 0.0;
    } else if (sat <= 0.000001) {
        rr = val;
        gg = val;
        bb = val;
    } else {
        float hf = h * 6.0;
        float f;
        float cc = val * sat;
        float qv;
        float tv;

        if (hf < 1.0) {
            f = hf;
            qv = cc * (1.0 - f);
            tv = cc * f;

            rr = cc;
            gg = tv;
            bb = 0.0;
        } else if (hf < 2.0) {
            f = hf - 1.0;
            qv = cc * (1.0 - f);
            tv = cc * f;

            rr = qv;
            gg = cc;
            bb = 0.0;
        } else if (hf < 3.0) {
            f = hf - 2.0;
            qv = cc * (1.0 - f);
            tv = cc * f;

            rr = 0.0;
            gg = cc;
            bb = tv;
        } else if (hf < 4.0) {
            f = hf - 3.0;
            qv = cc * (1.0 - f);
            tv = cc * f;

            rr = 0.0;
            gg = qv;
            bb = cc;
        } else if (hf < 5.0) {
            f = hf - 4.0;
            qv = cc * (1.0 - f);
            tv = cc * f;

            rr = tv;
            gg = 0.0;
            bb = cc;
        } else {
            f = hf - 5.0;
            qv = cc * (1.0 - f);
            tv = cc * f;

            rr = cc;
            gg = 0.0;
            bb = qv;
        }

        float m =
            val
            - (0.299 * rr
             + 0.587 * gg
             + 0.114 * bb);

        rr = rr + m;
        gg = gg + m;
        bb = bb + m;
    }

    rr = sb_clip(rr, 0.0, 1.0);
    gg = sb_clip(gg, 0.0, 1.0);
    bb = sb_clip(bb, 0.0, 1.0);

    /*
     * Undo the gamma transform before returning to ART.
     */
    r_out = pow(rr, gamma);
    g_out = pow(gg, gamma);
    b_out = pow(bb, gamma);
}