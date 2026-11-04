/**
 *  Equalizer by luminance ART CTL script.
 *
 *  Copyright 2023 Alberto Griggio <alberto.griggio@gmail.com>
 *
 *  ART is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  ART is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with ART.  If not, see <http://www.gnu.org/licenses/>.
 */

// @ART-label: "$CTL_EQUALIZER_BY_LUMINANCE;Equalizer by luminance"
// @ART-colorspace: "rec2020"

import "_artlib";


float conv(int v, float lo, float hi)
{
    float f;
    if (v < 0) {
        f = lo;
    } else {
        f = hi;
    }
    float vf = v;
    return pow(2, vf / 100.0 * f);
}


const float bounds[12][2] = {
    {2.0, 3.0}, // -16 EV
    {2.0, 3.0}, // -14 EV
    {2.0, 3.0}, // -12 EV
    {2.0, 3.0}, // -10 EV
    {2.0, 3.0}, //  -8 EV
    {2.0, 3.0}, //  -6 EV
    {2.5, 2.5}, //  -4 EV
    {3.0, 2.0}, //  -2 EV
    {3.0, 2.0}, //   0 EV
    {3.0, 2.0}, //   2 EV
    {3.0, 2.0}, //   4 EV
    {3.0, 2.0}  //   6 EV
};


float[12] get_factors(int blacks, int shadows,
                      int midtones, int highlights, int whites)
{
    const float centers[12] = {
        blacks, 
        blacks, 
        blacks, 
        blacks, 
        blacks, 
        shadows,
        midtones,
        highlights,
        whites,
        whites,
        whites,
        whites
    };
    float factors[12];
    for (int i = 0; i < 12; i = i+1) {
        factors[i] = conv(centers[i], bounds[i][0], bounds[i][1]);
    }
    return factors;
}


float lum(float rgb[3])
{
    float Y = luminance(rgb[0], rgb[1], rgb[2]);
    return clamp(Y, 1e-5, 32.0);
}


const float centers[12] = {
    -16.0, -14.0, -12.0, -10.0, -8.0, -6.0, -4.0, -2.0, 0.0, 2.0, 4.0, 6.0
};


float gauss_sum()
{
    float res = 0;
    for (int i = 0; i < 12; i = i+1) {
        res = res + gauss(centers[i], 2, 0);
    }
    return res;
}

const float w_sum = gauss_sum();

const float luma_lo = -14.0;
const float luma_hi = 4.0;

float get_gain(float y, float factors[12])
{
    float luma = clamp(log2(y), luma_lo, luma_hi);
    float correction = 0;
    for (int c = 0; c < 12; c = c+1) {
        correction = correction + gauss(centers[c], 2, luma) * factors[c];
    }
    return correction / w_sum;
}


const float noise = pow(2, -16);

float apply_vibrance(float x, float vib)
{
    float ax = fabs(x);
    if (ax > noise) {
        float res = pow(ax, vib);
        if (x < 0) {
            res = -res;
        }
        return res;
    } else {
        return x;
    }
}


// @ART-param: ["mode", "$CTL_TARGET;Target", ["$TP_COLORCORRECTION_L", "$TP_COLORCORRECTION_S", "$TP_SATURATION_VIBRANCE"]]
// @ART-param: ["blacks", "$TP_TONE_EQUALIZER_BAND_0", -100, 100, 0]
// @ART-param: ["shadows", "$TP_TONE_EQUALIZER_BAND_1", -100, 100, 0]
// @ART-param: ["midtones", "$TP_TONE_EQUALIZER_BAND_2", -100, 100, 0]
// @ART-param: ["highlights", "$TP_TONE_EQUALIZER_BAND_3", -100, 100, 0]
// @ART-param: ["whites", "$TP_TONE_EQUALIZER_BAND_4", -100, 100, 0]
// @ART-param: ["pivot", "$TP_TONE_EQUALIZER_PIVOT", -4, 4, 0, 0.05]
// @ART-param: ["detail", "$CTL_DETAIL_PROTECTION;Detail protection", 0, 100, 100]

void ART_main(varying float r, varying float g, varying float b,
              varying float guide,
              output varying float rout,
              output varying float gout,
              output varying float bout,
              int mode,
              int blacks,
              int shadows,
              int midtones,
              int highlights,
              int whites,
              float pivot,
              int detail)
{
    const float gain = 1.0 / pow(2, -pivot);
    const float factors[12] = get_factors(blacks, shadows, midtones,
                                          highlights, whites);
    float rgb[3] = { r * gain, g * gain, b * gain };
    float Y = intp(detail / 100.0, guide * gain, lum(rgb));
    float f = get_gain(Y, factors);

    if (mode == 0) {
        rout = r * f;
        gout = g * f;
        bout = b * f;
    } else if (mode == 1) {
        rgb[0] = r;
        rgb[1] = g;
        rgb[2] = b;
        float hsl[3] = rgb2jzhcl(r, g, b);
        f = log2(f) * 0.5;
        float sat = fmax(1 + f, 0);
        hsl[1] = hsl[1] * sat;
        rgb = jzhcl2rgb(hsl);
        rout = rgb[0];
        gout = rgb[1];
        bout = rgb[2];
    } else {
        f = log2(f);
        float vibrance = 1 - f * 0.05;
        rgb[0] = r;
        rgb[1] = g;
        rgb[2] = b;
        Y = lum(rgb);
        for (int i = 0; i < 3; i = i+1) {
            float v = apply_vibrance(rgb[i] - Y, vibrance);
            rgb[i] = fmax(Y + v, noise);
        }
        rout = rgb[0];
        gout = rgb[1];
        bout = rgb[2];
    }
}
