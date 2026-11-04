// @ART-colorspace: "rec2020"
// @ART-label: "$CTL_TETRAHEDRAL_COLOR_WARPING_HSL;Tetrahedral color warping (HSL)"

import "_artlib";
import "_tetrainterp";


float spow(float b, float e)
{
    if (b >= 0) {
        return pow(b, e);
    } else {
        return -pow(-b, e);
    }
}


float[3] torgb(float r, float g, float b, float dh, float ds, float dl)
{
    float hsl[3] = rgb2jzhcl(r, g, b);
    hsl[0] = hsl[0] + spow(dh, 1.5) * M_PI;
    hsl[1] = hsl[1] + spow(ds, 2);
    hsl[2] = jzhcl_lightness_gain(hsl[2], pow(2, 5*sgn(dl)*dl*dl));
    return jzhcl2rgb(hsl);
}


float[3] uvtorgb(float r, float g, float b, float du, float dv, float dl)
{
    float l = luminance(r, g, b);
    float u = l - b;
    float v = r - l;
    u = u + du;
    v = v + dv;
    l = l + dl;
    float bb = l - u;
    float rr = v + l;
    float gg = (l - rr * xyz_rec2020[1][0] - bb * xyz_rec2020[1][2]) / xyz_rec2020[1][1];
    float res[3] = { rr, gg, bb };
    return res;
}


void hs2uv(float h, float s, output float u, output float v)
{
    float a = h / 180.0 * M_PI;
    float f = s;
    u = f * sin(a);
    v = f * cos(a);
}

// @ART-param: ["RED_H", "$CTL_HUE;Hue", -1.0, 1.0, 0.0, 0.001, "$CTL_RED;Red"]
// @ART-param: ["RED_S", "$CTL_SATURATION;Saturation", -1.0, 1.0, 0.0, 0.001, "$CTL_RED;Red"]
// @ART-param: ["RED_L", "$CTL_LIGHTNESS;Lightness", -1.0, 1.0, 0.0, 0.001, "$CTL_RED;Red"]

// @ART-param: ["GRN_H", "$CTL_HUE;Hue", -1.0, 1.0, 0.0, 0.001, "$CTL_GREEN;Green"]
// @ART-param: ["GRN_S", "$CTL_SATURATION;Saturation", -1.0, 1.0, 0.0, 0.001, "$CTL_GREEN;Green"]
// @ART-param: ["GRN_L", "$CTL_LIGHTNESS;Lightness", -1.0, 1.0, 0.0, 0.001, "$CTL_GREEN;Green"]

// @ART-param: ["BLU_H", "$CTL_HUE;Hue", -1.0, 1.0, 0.0, 0.001, "$CTL_BLUE;Blue"]
// @ART-param: ["BLU_S", "$CTL_SATURATION;Saturation", -1.0, 1.0, 0.0, 0.001, "$CTL_BLUE;Blue"]
// @ART-param: ["BLU_L", "$CTL_LIGHTNESS;Lightness", -1.0, 1.0, 0.0, 0.001, "$CTL_BLUE;Blue"]

// @ART-param: ["CYN_H", "$CTL_HUE;Hue", -1.0, 1.0, 0.0, 0.001, "$CTL_CYAN;Cyan"]
// @ART-param: ["CYN_S", "$CTL_SATURATION;Saturation", -1.0, 1.0, 0.0, 0.001, "$CTL_CYAN;Cyan"]
// @ART-param: ["CYN_L", "$CTL_LIGHTNESS;Lightness", -1.0, 1.0, 0.0, 0.001, "$CTL_CYAN;Cyan"]

// @ART-param: ["MAG_H", "$CTL_HUE;Hue", -1.0, 1.0, 0.0, 0.001, "$CTL_MAGENTA;Magenta"]
// @ART-param: ["MAG_S", "$CTL_SATURATION;Saturation", -1.0, 1.0, 0.0, 0.001, "$CTL_MAGENTA;Magenta"]
// @ART-param: ["MAG_L", "$CTL_LIGHTNESS;Lightness", -1.0, 1.0, 0.0, 0.001, "$CTL_MAGENTA;Magenta"]

// @ART-param: ["YEL_H", "$CTL_HUE;Hue", -1.0, 1.0, 0.0, 0.001, "$CTL_YELLOW;Yellow"]
// @ART-param: ["YEL_S", "$CTL_SATURATION;Saturation", -1.0, 1.0, 0.0, 0.001, "$CTL_YELLOW;Yellow"]
// @ART-param: ["YEL_L", "$CTL_LIGHTNESS;Lightness", -1.0, 1.0, 0.0, 0.001, "$CTL_YELLOW;Yellow"]

// @ART-param: ["BLK_H", "$CTL_HUE;Hue", 0, 360.0, 0.0, 0.1, "$CTL_BLACK;Black"]
// @ART-param: ["BLK_S", "$CTL_SATURATION;Saturation", 0.0, 1.0, 0.0, 0.01, "$CTL_BLACK;Black"]
// @ART-param: ["BLK_O", "$CTL_OFFSET_LIFT;Offset/Lift", -1.0, 1.0, 0.0, 0.001, "$CTL_BLACK;Black"]

// @ART-param: ["WHT_H", "$CTL_HUE;Hue", 0, 360.0, 0.0, 0.1, "$CTL_WHITE;White"]
// @ART-param: ["WHT_S", "$CTL_SATURATION;Saturation", 0.0, 1.0, 0.0, 0.01, "$CTL_WHITE;White"]

void ART_main(varying float r, varying float g, varying float b,
              output varying float rout,
              output varying float gout,
              output varying float bout,
              float RED_H, float RED_S, float RED_L,
              float GRN_H, float GRN_S, float GRN_L,
              float BLU_H, float BLU_S, float BLU_L,
              float CYN_H, float CYN_S, float CYN_L,
              float MAG_H, float MAG_S, float MAG_L,
              float YEL_H, float YEL_S, float YEL_L,
              float BLK_H, float BLK_S, float BLK_O,
              float WHT_H, float WHT_S)
{
    float blk_u;
    float blk_v;
    hs2uv(BLK_H, BLK_S * 0.02, blk_u, blk_v);
    float blk[3] = uvtorgb(0, 0, 0, blk_u, blk_v, BLK_O / 25);
    float wht_u;
    float wht_v;
    hs2uv(WHT_H, WHT_S * 0.25, wht_u, wht_v);
    float wht[3] = uvtorgb(1, 1, 1, wht_u, wht_v, 0);
    float red[3] = torgb(1, 0, 0, RED_H, RED_S, RED_L);
    float grn[3] = torgb(0, 1, 0, GRN_H, GRN_S, GRN_L);
    float blu[3] = torgb(0, 0, 1, BLU_H, BLU_S, BLU_L);
    float cyn[3] = torgb(0, 1, 1, CYN_H, CYN_S, CYN_L);
    float mag[3] = torgb(1, 0, 1, MAG_H, MAG_S, MAG_L);
    float yel[3] = torgb(1, 1, 0, YEL_H, YEL_S, YEL_L);

    float rgb[3] = tetrainterp(r, g, b, blk, wht, red, grn, blu, cyn, mag, yel);

    rout = rgb[0];
    gout = rgb[1];
    bout = rgb[2];
}
