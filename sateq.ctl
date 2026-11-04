/**
 *  Equalizer by saturation ART CTL script
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

// @ART-label: "$CTL_EQUALIZER_BY_SATURATION;Equalizer by saturation"
// @ART-colorspace: "rec2020"

import "_artlib";


float[3] to_hsl(float r, float g, float b)
{
    return rgb2jzhcl(r, g, b);
}


float[3] to_rgb(float hsl[3])
{
    return jzhcl2rgb(hsl);
}


float sat(float r, float g, float b)
{
    return to_hsl(r, g, b)[1];
}


const int num_bands = 6;
const float centers[6] = { 0.002, 0.05, 0.12, 0.35, 0.75, 0.9 };
const float sigma2[6] = { 0.001, 0.002, 0.0025, 0.025, 0.05, 0.05 };

float gauss_sum()
{
    float res = 0;
    for (int i = 0; i < num_bands; i = i+1) {
        res = res + gauss(centers[i], sigma2[i], 0);
    }
    return res;
}

const float w_sum = gauss_sum();


float get_factor(float s,
                 int gray, int muted, int average, int vivid, int pure)
{
    const float f[num_bands] = { gray, muted, average, vivid, pure, pure };
    float res = 0;
    for (int i = 0; i < num_bands; i = i+1) {
        res = res + f[i]/100 * gauss(centers[i], sigma2[i], s);
    }
    return res / w_sum;
}


const float noise = pow(2, -16);

// @ART-param: ["mode", "$CTL_TARGET;Target", ["$TP_COLORCORRECTION_S", "$TP_COLORCORRECTION_L", "$TP_COLORCORRECTION_H"]]
// @ART-param: ["gray", "$CTL_NEUTRAL;Neutral", -100, 100, 0]
// @ART-param: ["muted", "$CTL_MUTED;Muted", -100, 100, 0]
// @ART-param: ["average", "$CTL_AVERAGE;Average", -100, 100, 0]
// @ART-param: ["vivid", "$CTL_VIVID;Vivid", -100, 100, 0]
// @ART-param: ["pure", "$CTL_PURE;Pure", -100, 100, 0]

void ART_main(varying float r, varying float g, varying float b,
              output varying float rout,
              output varying float gout,
              output varying float bout,
              int mode,
              int gray,
              int muted,
              int average,
              int vivid,
              int pure)
{
    float hsl[3] = to_hsl(r, g, b);
    float f = get_factor(hsl[1], gray, muted, average, vivid, pure);
    if (mode == 0) {
        float s = fmax(1 + f*2, 0);
        hsl[1] = hsl[1] * s;
    } else if (mode == 1) {
        float s = pow(2, f);
        hsl[2] = hsl[2] * s;
    } else {
        float s = f*f;
        if (f < 0) {
            s = -s;
        }
        hsl[0] = hsl[0] + s * M_PI;
    }
    float rgb[3] = to_rgb(hsl);
    rout = rgb[0];
    gout = rgb[1];
    bout = rgb[2];
}
