// @ART-label: "The One tone mapper"
// @ART-colorspace: "rec2020"
//
// inspired by the AgX picture formation (https://github.com/sobotka/AgX)
// the name is obviously a joke...
// 
// @ART-param: ["curve", "Base Curve", 0, ["CatmullRom", 0, 0, 0.1, 0.1, 0.55, 0.87, 1, 1]]
// @ART-param: ["rcurve", "R", 0, ["Linear"], "RGB Curves"]
// @ART-param: ["gcurve", "G", 0, ["Linear"], "RGB Curves"]
// @ART-param: ["bcurve", "B", 0, ["Linear"], "RGB Curves"]
// @ART-param: ["brightness", "Brightness", -1, 1, 0, 0.01]
// @ART-param: ["contrast", "Contrast", -1, 1, 0, 0.01]
// @ART-param: ["sat", "Saturation", 0.0, 2.0, 1.0, 0.01]
// @ART-param: ["white_pt", "White point", 1, 10, 1, 0.1]
// @ART-param: ["white_ev", "White relative exposure", 1, 10, 4.5, 0.01]
// @ART-param: ["black_ev", "Black relative exposure", -20, -1, -13.5, 0.01]

import "_artlib";

const float AgXInsetMatrix[3][3] = {
    {0.856627153315983, 0.0951212405381588, 0.0482516061458583},
    {0.137318972929847, 0.761241990602591, 0.101439036467562},
    {0.11189821299995, 0.0767994186031903, 0.811302368396859}
};
const float AgXInsetMatrix_t[3][3] = transpose_f33(AgXInsetMatrix);

const float AgXOutsetMatrix_t[3][3] = invert_f33(AgXInsetMatrix_t);

float[3] tone_mapping(float rgb[3], float white_pt, float curve[256],
                      float rcurve[256], float gcurve[256], float bcurve[256],
                      float sat, float white_ev, float black_ev, float pivot)
{
    float v[3] = {fmax(0.0, rgb[0]), fmax(0.0, rgb[1]), fmax(0.0, rgb[2])};

    v = mult_f3_f33(v, AgXInsetMatrix_t);

    float hsl[3] = rgb2hsl(v[0], v[1], v[2]);
    hsl[1] = hsl[1] * sat;
    v = hsl2rgb(hsl);

    const float small_value = 1e-10;
    const float dr = white_ev - black_ev;
    const float p = -black_ev / dr;
    for (int i = 0; i < 3; i = i+1) {
        v[i] = fmax(v[i], small_value);
        v[i] = log2(v[i]);
        v[i] = (v[i] - black_ev) / dr;
        v[i] = clamp(v[i], 0.0, 1.0);
        float e = log(pivot) / log(p);
        v[i] = pow(v[i], e);
        v[i] = luteval(curve, v[i]);
    }
    
    v[0] = luteval(rcurve, v[0]);
    v[1] = luteval(gcurve, v[1]);
    v[2] = luteval(bcurve, v[2]);

    v = mult_f3_f33(v, AgXOutsetMatrix_t);

    for (int i = 0; i < 3; i = i+1) {
        v[i] = pow(fmax(0.0, v[i]), 2.2);
    }

    if (white_pt > 1) {
        for (int i = 0; i < 3; i = i+1) {
            float x = v[i];
            float f = (pow(white_pt, x) - 1) / (white_pt - 1);
            v[i] = intp(x*x*x, f * white_pt, x);
        }
    }

    return v;
}


void ART_main(varying float r, varying float g, varying float b,
              output varying float rout,
              output varying float gout,
              output varying float bout,
              float curve[256],
              float rcurve[256], float gcurve[256], float bcurve[256],
              float sat, float white_pt, float brightness,
              float white_ev, float black_ev, float contrast)
{
    float rgb[3] = { r, g, b };
    const float c = 1.0 + contrast;
    for (int i = 0; i < 3; i = i+1) {
        rgb[i] = pow(fmax(rgb[i], 0) / 0.18, c) * 0.18;
    }
    const float pivot = 0.5 + brightness * 0.3;
    rgb = tone_mapping(rgb, white_pt, curve, rcurve, gcurve, bcurve,
                       sat, white_ev, black_ev, pivot);
    rout = rgb[0];
    gout = rgb[1];
    bout = rgb[2];
}
