// 
// @ART-colorspace: "rec709"
// @ART-label: "$CTL_SOFTLIGHT;Softlight"
// 

// @ART-param: ["strength", "$CTL_STRENGTH;Strength", 0.0, 100.0, 0.0, 0.1]
// @ART-param: ["pivot", "$CTL_SHADOWS_HIGHLIGHTS_BALANCE;Shadows/Highlights balance", -1, 1, 0, 0.01]

import "_artlib";

// see https://en.wikipedia.org/wiki/Blend_modes#Soft_Light
float sl(float x)
{
    float v = fmax(x, 0);
    float a = v;
    float b = v;
    float bb = 2*b;
    v = (1 - bb) * a*a + bb*a;
    v = fmax(v, 0);
    return v;
}


void ART_main(varying float r, varying float g, varying float b,
              output varying float rout,
              output varying float gout,
              output varying float bout,
              float strength, float pivot)
{
    const float s = strength / 100;
    const float p = fmax(pow(0.5 - pivot / 2, 2.4), 0.001);
    const float f = p / intp(s, pq_curve(sl(pq_curve(p, false)), true), p);
    float rgb[3] = { r, g, b };
    float hue = rgb2okhcl(r, g, b)[0];
    for (int i = 0; i < 3; i = i+1) {
        float v = pq_curve(rgb[i], false);
        rgb[i] = intp(s, pq_curve(sl(v), true) * f, rgb[i]);
    }
    float hcl[3] = rgb2okhcl(rgb[0], rgb[1], rgb[2]);
    hcl[0] = hue;
    rgb = okhcl2rgb(hcl);
    rout = rgb[0];
    gout = rgb[1];
    bout = rgb[2];
}
