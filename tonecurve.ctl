// @ART-label: "$CTL_TONE_CURVE;Tone curve"
// @ART-colorspace: "rec2020"

import "_artlib";

const float c = 0;
const float a = 1;
const float m = 0.5;//0.18;
const float b = (a / (m - c)) * (1.0 - ((m - c) / a)) * m;
const float s = 1;
const float g = s * pow(m + b, 2) / (a * b);

float ro(float x)
{
    return a * (x / (x + b)) + c;
}

float iro(float y)
{
    return (-b * ((y - c) / a)) / (((y - c) / a) - 1);
}

float contr(float x)
{
    return m * pow(x / m, g);
}

float icontr(float y)
{
    return pow(y / m, 1.0/g) * m;
}

float gam(float x)
{
    return pow(x, 1.0/2.2);
}


float igam(float x)
{
    return pow(x, 2.2);
}


float enc(float x)
{
    float y = ite(x <= m, x, ro(contr(x)));
    return gam(y);
}


float dec(float x)
{
    float y = igam(x);
    return ite(y <= m, y, icontr(iro(y)));
}


// @ART-param: ["curve", "$CTL_CURVE;Curve", 0, ["CatmullRom", 0, 0, 1, 1]]

// @ART-preset: ["contrast", "Contrast boost", {"curve": ["Spline", 0, 0, 0.123506, 0.10338, 0.306773, 0.333996, 0.689243, 0.763419, 1, 1]}]
// @ART-preset: ["shadow_lifting", "Shadows lifting", {"curve": ["CatmullRom", 0, 0, 0.14741, 0.182903, 0.262948, 0.27833, 0.34, 0.34, 1, 1]}]

void ART_main(varying float r, varying float g, varying float b,
              output varying float rout,
              output varying float gout,
              output varying float bout,
              float curve[256])
{
    float rgb[3] = { r, g, b };
    for (int i = 0; i < 3; i = i+1) {
        float x = enc(rgb[i]);
        float y = luteval(curve, x);
        rgb[i] = dec(y);
    }
    rout = rgb[0];
    gout = rgb[1];
    bout = rgb[2];
}
