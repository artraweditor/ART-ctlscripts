// @ART-label: "$CTL_GRAPHICAL_EQUALIZER_BY_HUE;Graphical equalizer by hue"
// @ART-colorspace: "rec2020"

import "_artlib";

float hue01(float h)
{
    float v = h / (2 * M_PI);
    if (v < 0.0) {
        return 1.0 + v;
    } else if (v > 1.0) {
        return v - 1.0;
    } else {
        return v;
    }
}


float tolin(float y, float base)
{
    float v = (y - 0.5) * 2.0;
    return sgn(v) * clamp(log2lin(fabs(v), base), 0, 1);
}

// @ART-param: ["hcurve", "H", 2, ["ControlPoints", 0.0, 0.5, 0.35, 0.35, 0.16666666666666666, 0.5, 0.35, 0.35, 0.3333333333333333, 0.5, 0.35, 0.35, 0.5, 0.5, 0.35, 0.35, 0.6666666666666666, 0.5, 0.35, 0.35, 0.8333333333333333, 0.5, 0.35, 0.35], [[0.0, 0.6, 0.3, 0.48947368421052634], [0.16666666666666666, 0.6, 0.4105263157894737, 0.3], [0.3333333333333333, 0.48947368421052634, 0.6, 0.3], [0.5, 0.3, 0.6, 0.41052631578947363], [0.6666666666666666, 0.3, 0.48947368421052634, 0.6], [0.8333333333333333, 0.41052631578947363, 0.3, 0.6], [1.0, 0.6, 0.3, 0.48947368421052634]], 0, "$CTL_CHANNEL;Channel"]
// @ART-param: ["scurve", "S", 2, ["ControlPoints", 0.0, 0.5, 0.35, 0.35, 0.16666666666666666, 0.5, 0.35, 0.35, 0.3333333333333333, 0.5, 0.35, 0.35, 0.5, 0.5, 0.35, 0.35, 0.6666666666666666, 0.5, 0.35, 0.35, 0.8333333333333333, 0.5, 0.35, 0.35], [[0.0, 0.6, 0.3, 0.48947368421052634], [0.16666666666666666, 0.6, 0.4105263157894737, 0.3], [0.3333333333333333, 0.48947368421052634, 0.6, 0.3], [0.5, 0.3, 0.6, 0.41052631578947363], [0.6666666666666666, 0.3, 0.48947368421052634, 0.6], [0.8333333333333333, 0.41052631578947363, 0.3, 0.6], [1.0, 0.6, 0.3, 0.48947368421052634]], 0, "$CTL_CHANNEL;Channel"]
// @ART-param: ["lcurve", "L", 2, ["ControlPoints", 0.0, 0.5, 0.35, 0.35, 0.16666666666666666, 0.5, 0.35, 0.35, 0.3333333333333333, 0.5, 0.35, 0.35, 0.5, 0.5, 0.35, 0.35, 0.6666666666666666, 0.5, 0.35, 0.35, 0.8333333333333333, 0.5, 0.35, 0.35], [[0.0, 0.6, 0.3, 0.48947368421052634], [0.16666666666666666, 0.6, 0.4105263157894737, 0.3], [0.3333333333333333, 0.48947368421052634, 0.6, 0.3], [0.5, 0.3, 0.6, 0.41052631578947363], [0.6666666666666666, 0.3, 0.48947368421052634, 0.6], [0.8333333333333333, 0.41052631578947363, 0.3, 0.6], [1.0, 0.6, 0.3, 0.48947368421052634]], 0, "$CTL_CHANNEL;Channel"]
// @ART-guides: ["H"]
void ART_main(varying float r, varying float g, varying float b,
              varying float guide_h, 
              output varying float rout,
              output varying float gout,
              output varying float bout,
              float hcurve[256], float scurve[256], float lcurve[256])
{
    float hsl[3] = rgb2okhcl(r, g, b);
    float h = hue01(guide_h);
    float v = luteval(hcurve, h);
    float f = tolin(v, 50) * M_PI;
    hsl[0] = hsl[0] + f;
    v = luteval(scurve, h);
    f = tolin(v, 2);
    float s = fmax(1.0 + f, 0);
    hsl[1] = hsl[1] * s;
    v = luteval(lcurve, h);
    s = fmin(hsl[1], 1);
    f = tolin(v, 10);
    hsl[2] = hsl[2] * pow(2, 10 * f * s);
    float rgb[3] = okhcl2rgb(hsl);
    rout = rgb[0];
    gout = rgb[1];
    bout = rgb[2];
}

// @ART-pipette: ["hcurve", "scurve", "lcurve"]
void ART_fill_pipette(varying float r, varying float g, varying float b,
                      varying float guide_h,
                      output varying float rout,
                      output varying float gout,
                      output varying float bout,
                      int curve_id)
{
    float hsl[3] = rgb2okhcl(r, g, b);
    float h = hue01(hsl[0]);
    rout = h;
    gout = h;
    bout = h;
}
