// @ART-label: "$CTL_GRAPHICAL_EQUALIZER_BY_SATURATION;Graphical equalizer by saturation"
// @ART-colorspace: "rec2020"

import "_artlib";

float tolin(float y, float base)
{
    float v = (y - 0.5) * 2.0;
    return sgn(v) * clamp(log2lin(fabs(v), base), 0, 1);
}

// @ART-param: ["hcurve", "H", 1, ["ControlPoints", 0.0, 0.5, 0.35, 0.35, 1, 0.5, 0.35, 0.35], [[0.0, 0.6247426875000001, 0.6247426875000001, 0.6247426875000001], [0.16666666666666666, 0.6252545086395497, 0.6246428485887556, 0.6240446952267805], [0.3333333333333333, 0.6305332826764821, 0.6236131391613252, 0.6168458063862508], [0.5, 0.6486781933883669, 0.6200736836951146, 0.5921008193263192], [0.6666666666666666, 0.6902557933623452, 0.6119633068607208, 0.535399676527902], [0.8333333333333334, 0.767801045044281, 0.596836863457253, 0.42964791616394454], [1.0, 0.8955420238967149, 0.5719189394708761, 0.2554421061206866]], 0, "$CTL_CHANNEL;Channel"]
// @ART-param: ["scurve", "S", 1, ["ControlPoints", 0.0, 0.5, 0.35, 0.35, 1, 0.5, 0.35, 0.35], [[0.0, 0.6247426875000001, 0.6247426875000001, 0.6247426875000001], [0.16666666666666666, 0.6252545086395497, 0.6246428485887556, 0.6240446952267805], [0.3333333333333333, 0.6305332826764821, 0.6236131391613252, 0.6168458063862508], [0.5, 0.6486781933883669, 0.6200736836951146, 0.5921008193263192], [0.6666666666666666, 0.6902557933623452, 0.6119633068607208, 0.535399676527902], [0.8333333333333334, 0.767801045044281, 0.596836863457253, 0.42964791616394454], [1.0, 0.8955420238967149, 0.5719189394708761, 0.2554421061206866]], 0, "$CTL_CHANNEL;Channel"]
// @ART-param: ["lcurve", "L", 1, ["ControlPoints", 0.0, 0.5, 0.35, 0.35, 1, 0.5, 0.35, 0.35], [[0.0, 0.6247426875000001, 0.6247426875000001, 0.6247426875000001], [0.16666666666666666, 0.6252545086395497, 0.6246428485887556, 0.6240446952267805], [0.3333333333333333, 0.6305332826764821, 0.6236131391613252, 0.6168458063862508], [0.5, 0.6486781933883669, 0.6200736836951146, 0.5921008193263192], [0.6666666666666666, 0.6902557933623452, 0.6119633068607208, 0.535399676527902], [0.8333333333333334, 0.767801045044281, 0.596836863457253, 0.42964791616394454], [1.0, 0.8955420238967149, 0.5719189394708761, 0.2554421061206866]], 0, "$CTL_CHANNEL;Channel"]
void ART_main(varying float r, varying float g, varying float b,
              output varying float rout,
              output varying float gout,
              output varying float bout,
              float hcurve[256], float scurve[256], float lcurve[256])
{
    float hsl[3] = rgb2jzhcl(r, g, b);
    float y = pow(clamp(jzhcl_ok_chroma(hsl), 0, 1), 1.0/3.5);
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
                      output varying float rout,
                      output varying float gout,
                      output varying float bout,
                      int curve_id)
{
    float hsl[3] = rgb2jzhcl(r, g, b);
    float y = pow(clamp(jzhcl_ok_chroma(hsl), 0, 1), 1.0/3.5);
    rout = y;
    gout = y;
    bout = y;
}
