// @ART-label: "$CTL_GRAPHICAL_EQUALIZER_BY_LUMINANCE;Graphical equalizer by luminance"
// @ART-colorspace: "rec2020"

import "_artlib";

float tolin(float y, float base)
{
    float v = (y - 0.5) * 2.0;
    return sgn(v) * clamp(log2lin(fabs(v), base), 0, 1);
}


float lum(float hsl[3], float guide, int detail)
{
    float g[3] = rgb2jzhcl(guide, guide, guide);
    float ret = intp(detail / 100.0, jzhcl_ok_lightness(g), jzhcl_ok_lightness(hsl));
    return clamp(ret, 0, 1);   
}

// @ART-param: ["hcurve", "H", 1, ["ControlPoints", 0.0, 0.5, 0.35, 0.35, 1, 0.5, 0.35, 0.35], [[0.0, 0.0, 0.0, 0.0], [0.16666666666666666, 0.01941186441032164, 0.01941186441032164, 0.01941186441032164], [0.3333333333333333, 0.08919350686224782, 0.08919350686224782, 0.08919350686224782], [0.5, 0.217637640824031, 0.217637640824031, 0.217637640824031], [0.6666666666666666, 0.40982573843632336, 0.40982573843632336, 0.40982573843632336], [0.8333333333333334, 0.6695781277796022, 0.6695781277796022, 0.6695781277796022], [1.0, 1.0, 1.0, 1.0]], 0, "$CTL_CHANNEL;Channel"]
// @ART-param: ["scurve", "S", 1, ["ControlPoints", 0.0, 0.5, 0.35, 0.35, 1, 0.5, 0.35, 0.35], [[0.0, 0.0, 0.0, 0.0], [0.16666666666666666, 0.01941186441032164, 0.01941186441032164, 0.01941186441032164], [0.3333333333333333, 0.08919350686224782, 0.08919350686224782, 0.08919350686224782], [0.5, 0.217637640824031, 0.217637640824031, 0.217637640824031], [0.6666666666666666, 0.40982573843632336, 0.40982573843632336, 0.40982573843632336], [0.8333333333333334, 0.6695781277796022, 0.6695781277796022, 0.6695781277796022], [1.0, 1.0, 1.0, 1.0]], 0, "$CTL_CHANNEL;Channel"]
// @ART-param: ["lcurve", "L", 1, ["ControlPoints", 0.0, 0.5, 0.35, 0.35, 1, 0.5, 0.35, 0.35], [[0.0, 0.0, 0.0, 0.0], [0.16666666666666666, 0.01941186441032164, 0.01941186441032164, 0.01941186441032164], [0.3333333333333333, 0.08919350686224782, 0.08919350686224782, 0.08919350686224782], [0.5, 0.217637640824031, 0.217637640824031, 0.217637640824031], [0.6666666666666666, 0.40982573843632336, 0.40982573843632336, 0.40982573843632336], [0.8333333333333334, 0.6695781277796022, 0.6695781277796022, 0.6695781277796022], [1.0, 1.0, 1.0, 1.0]], 0, "$CTL_CHANNEL;Channel"]
// @ART-param: ["detail", "$CTL_DETAIL_PROTECTION;Detail protection", 0, 100, 100]
void ART_main(varying float r, varying float g, varying float b,
              varying float guide,
              output varying float rout,
              output varying float gout,
              output varying float bout,
              float hcurve[256], float scurve[256], float lcurve[256],
              int detail)
{
    float hsl[3] = rgb2jzhcl(r, g, b);
    float y = lum(hsl, guide, detail);
    float v = luteval(hcurve, y);
    float f = tolin(v, 50) * M_PI;
    hsl[0] = hsl[0] + f;
    v = luteval(scurve, y);
    f = tolin(v, 2);
    float s = fmax(1.0 + f, 0);
    hsl[1] = hsl[1] * s;
    v = luteval(lcurve, y) - 0.5;
    f = 1 + sgn(v) * pow(v, 2) * 5;
    // f scales the OKLab lightness, i.e. the luminance by f^3
    hsl[2] = jzhcl_lightness_gain(hsl[2], pow(fmax(f, 0.0), 3));
    float rgb[3] = jzhcl2rgb(hsl);
    rout = rgb[0];
    gout = rgb[1];
    bout = rgb[2];
}

// @ART-pipette: ["hcurve", "scurve", "lcurve"]
void ART_fill_pipette(varying float r, varying float g, varying float b,
                      varying float guide,
                      output varying float rout,
                      output varying float gout,
                      output varying float bout,
                      int curve_id, int detail)
{
    float y = lum(rgb2jzhcl(r, g, b), guide, detail);
    rout = y;
    gout = y;
    bout = y;
}
