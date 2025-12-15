// @ART-label: "$CTL_SATURATION_VIBRANCE;Saturation/Vibrance"
// @ART-colorspace: "rec709"


const float noise = pow(2.0, -16.0);

float apply_vibrance(float x, float vib)
{
    float ax = fabs(x);
    if (ax > noise) {
        return ax / x * pow(ax, vib);
    } else {
        return x;
    }
}


// @ART-param: ["saturation", "$CTL_SATURATION;Saturation", -100, 100, 0]
// @ART-param: ["vibrance", "$CTL_VIBRANCE;Vibrance", -100, 100, 0]
void ART_main(varying float r, varying float g, varying float b,
              output varying float rout,
              output varying float gout,
              output varying float bout,
              int saturation, int vibrance)
{
    const float v = 1.0 - vibrance / 1000.0;
    const float s = 1.0 + saturation / 100.0;
    float rgb[3] = { r, g, b };
    float Y = 0.2126 * r + 0.7152 * g + 0.0722 * b;
    for (int i = 0; i < 3; i = i+1) {
        float l = rgb[i] - Y;
        rgb[i] = Y + s * apply_vibrance(l, v);
    }
    rout = rgb[0];
    gout = rgb[1];
    bout = rgb[2];
}
