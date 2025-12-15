// customized tone mapping with bits taken from
//  https://github.com/thatcherfreeman/utility-dctls/
//
// Copyright of the original code
/*
MIT License

Copyright (c) 2023 Thatcher Freeman

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

// 
// @ART-colorspace: "rec2020"
// @ART-label: "$CTL_ART_OUTPUT_TRANSFORM;ART output transform"
// 

// @ART-param: ["mode", "$CTL_COLOR_MODE;Color mode", ["Legacy", "Blender-AgX", "Neutral"], 2]
// @ART-param: ["evgain", "$CTL_GAIN;Gain (Ev)", -4.0, 4.0, 0.0, 0.01]
// @ART-param: ["brightness", "$CTL_BRIGHTNESS;Brightness", -100, 100, 0]
// @ART-param: ["contrast", "$CTL_CONTRAST;Contrast", -100, 100, 25]
// @ART-param: ["sat", "$CTL_SATURATION;Saturation", -100, 100, 0]
// @ART-param: ["white_point", "$CTL_WHITE_POINT;White point", 0.8, 40.0, 1.0, 0.1]
// @ART-param: ["user_black_point", "$CTL_BLACK_POINT;Black point", -0.05, 0.05, 0.0, 0.0001]
// @ART-param: ["scale_mid_gray", "$CTL_SCALE_MID_GRAY_WITH_WP;Scale mid gray with white point", false]
// @ART-param: ["gc_colorspace", "$CTL_TARGET_SPACE;Target space", ["$CTL_NONE;None", "Rec.2020", "Rec.709 / sRGB", "DCI-P3", "Adobe RGB"], 2, "$CTL_GAMUT_COMPRESSION;Gamut compression"]
// @ART-param: ["gc_strength", "$CTL_STRENGTH;Strength", 0.7, 2, 1, 0.01, "$CTL_GAMUT_COMPRESSION;Gamut compression"]
// @ART-param: ["hue_preservation", "$CTL_HUE_PRESERVATION;Hue preservation", 0, 1, 0, 0.1]

import "_artlib";

const float to_rec709[3][3] = transpose_f33(mult_f33_f33(invert_f33(xyz_rec709),
                                                         xyz_rec2020));
const float from_rec709[3][3] = invert_f33(to_rec709);

const float to_p3[3][3] = transpose_f33(mult_f33_f33(invert_f33(xyz_p3),
                                                     xyz_rec2020));
const float from_p3[3][3] = invert_f33(to_p3);

const float to_adobe[3][3] = transpose_f33(mult_f33_f33(invert_f33(xyz_adobe),
                                                        xyz_rec2020));
const float from_adobe[3][3] = invert_f33(to_adobe);

float powf(float base, float exp)
{
    return pow(fmax(base, 0), exp);
}


float scene_contrast(float x, float mid_gray, float gamma)
{
    return mid_gray * powf(x / mid_gray, gamma);
}


float display_contrast(float x, float a, float b, float w, float o)
{
    float y = pow(fmax(x - o, 0) / w, a);
    float r = log(y * (b - 1) + 1) / log(b);
    return r * w + o;
}


// g(x) = a * (x / (x+b)) + c
float rolloff_function(float x, float a, float b, float c)
{
    return a * (x / (x + b)) + c;
}


float[3] tonemap(float p_R, float p_G, float p_B,
                 float target_slope, float white_point, float black_point,
                 float mid_gray_in, float mid_gray_out)
{
    float out[3] = { p_R, p_G, p_B };
    for (int i = 0; i < 3; i = i+1) {
        out[i] = out[i] * mid_gray_out / mid_gray_in;
    }

    // Constraint 1: h(0) = black_point
    float c = black_point;
    // Constraint 2: h(infty) = white_point
    float a = white_point - c;
    // Constraint 3: h(mid_out) = mid_out
    float b = (a / (mid_gray_out - c)) *
        (1.0 - ((mid_gray_out - c) / a)) * mid_gray_out;
    // Constraint 4: h'(mid_out) = target_slope
    float gamma = target_slope * powf((mid_gray_out + b), 2.0) / (a * b);

    // h(x) = g(m_i * ((x/m_i)**gamma))
    for (int i = 0; i < 3; i = i+1) {
        out[i] = rolloff_function(scene_contrast(out[i], mid_gray_out, gamma),
                                  a, b, c);
    }
    return out;
}


float[3] to_hsl(float r, float g, float b, int mode)
{
    if (mode == 0) {
        return rgb2hsl(r, g, b);
    } else {
        return rgb2okhcl(r, g, b);
    }
}

const float rec2020_xyz_t[3][3] = invert_f33(xyz_rec2020_t);

float[3] to_rgb(float hsl[3], int mode)
{
    if (mode == 0) {
        return hsl2rgb(hsl);
    } else {
        return okhcl2rgb(hsl);
    }
}

const float hpars[2][4] = { // parameters for hue tweaks
    {
        rgb2hsl(1, 0, 0)[0], // rhue
        rgb2hsl(0, 0, 1)[0], // bhue
        rgb2hsl(1, 1, 0)[0], // yhue
        rgb2hsl(1, 0.5, 0)[0] // ohue
    },
    {
        rgb2okhcl(1, 0, 0)[0], // rhue
        rgb2okhcl(0, 0, 1)[0], // bhue
        rgb2okhcl(1, 1, 0)[0], // yhue
        rgb2okhcl(1, 0.5, 0)[0] // ohue
    }
};

const float rpars[2][3] = {
    {
        fabs(hpars[0][3] - hpars[0][2]) * 0.8,
        fabs(hpars[0][3] - hpars[0][0]),
        fabs(hpars[0][3] - hpars[0][0])
    },
    {
        fabs(hpars[1][3] - hpars[1][2]) * 0.8,
        fabs(hpars[1][3] - hpars[1][0]),
        fabs(hpars[1][3] - hpars[1][0])
    }
};
/* const float rhue = to_hsl(1, 0, 0)[0]; */
/* const float bhue = to_hsl(0, 0, 1)[0]; */
/* const float yhue = to_hsl(1, 1, 0)[0]; */
/* const float ohue = to_hsl(1, 0.5, 0)[0]; */
/* const float yrange = fabs(ohue - yhue) * 0.8; */
/* const float rrange = fabs(ohue - rhue); */
/* const float brange = rrange; */

float[3] creative_hue_sat_tweaks(float hue_shift_amount, float sat_factor,
                                 float in_r, float in_g, float in_b,
                                 float white_point, float rgb[3], int mode)
{
    const float rhue = hpars[mode][0];
    const float bhue = hpars[mode][1];
    const float yhue = hpars[mode][2];
    const float ohue = hpars[mode][3];
    const float yrange = rpars[mode][0];
    const float rrange = rpars[mode][1];
    const float brange = rpars[mode][2];
    
    float hue = to_hsl(in_r, in_g, in_b, mode)[0];
    const float base_shift = 15.0 * hue_shift_amount;
    float hue_shift = base_shift * M_PI / 180.0 * gauss(rhue, rrange, hue);
    hue_shift = hue_shift + -base_shift * M_PI / 180.0 * gauss(bhue, brange, hue);
    hue_shift = hue_shift * clamp((rgb[0] + rgb[1] + rgb[2]) / (3.0 * white_point), 0, 1);
    hue = hue + hue_shift;
    
    float hsl[3] = to_hsl(rgb[0], rgb[1], rgb[2], mode);
    hsl[0] = hue;
    hsl[1] = hsl[1] * sat_factor;
    float res[3] = to_rgb(hsl, mode);
    return res;
}


// hand-tuned gamut compression parameters
const float base_dl[3] = {1.1, 1.2, 1.5};
const float base_th[3] = {0.85, 0.75, 0.95};

const float mid_gray_in = 0.18;
//const float usr_mid_gray_out = 0.18;
const float base_black_point = 1.0/4096.0;

const float AgXInsetMatrix[3][3] = {
    {0.856627153315983, 0.0951212405381588, 0.0482516061458583},
    {0.137318972929847, 0.761241990602591, 0.101439036467562},
    {0.11189821299995, 0.0767994186031903, 0.811302368396859}
};
const float AgXInsetMatrix_t[3][3] = transpose_f33(AgXInsetMatrix);

const float AgXOutsetMatrix_t[3][3] = invert_f33(AgXInsetMatrix_t);

const int MODE_NEUTRAL = 2;
const int MODE_BLENDERAGX = 1;
const int MODE_LEGACY = 0;

void ART_main(varying float r, varying float g, varying float b,
              output varying float rout,
              output varying float gout,
              output varying float bout,
              float evgain,
              int contrast, int sat, float white_point,
              bool scale_mid_gray, int gc_colorspace, float gc_strength,
              float hue_preservation,
              int mode, int brightness, float user_black_point)
{
    float gain = pow(2, evgain);
    float rgb[3] = { r * gain, g * gain, b * gain };
    
    if (gc_colorspace > 0) {
        float dl[3] = base_dl;
        float th[3] = base_th;
        for (int i = 0; i < 3; i = i+1) {
            dl[i] = dl[i] * gc_strength;
            th[i] = th[i] / sqrt(gc_strength);
        }
        
        float to_out[3][3] = identity_33;
        float from_out[3][3] = identity_33;
        if (gc_colorspace == 2) {
            to_out = to_rec709;
            from_out = from_rec709;
        } else if (gc_colorspace == 3) {
            to_out = to_p3;
            from_out = from_p3;
        } else if (gc_colorspace == 4) {
            to_out = to_adobe;
            from_out = from_adobe;
        }

        rgb = gamut_compress(rgb, th, dl, to_out, from_out);
    }

    float usr_mid_gray_out = mid_gray_in + brightness / 300.0;

    float black_point = base_black_point + user_black_point;
    float mid_gray_out;
    if (scale_mid_gray) {
        const float dr = white_point - black_point;
        mid_gray_out = usr_mid_gray_out * dr + black_point;
    } else {
        mid_gray_out = usr_mid_gray_out;
    }

    float sat_factor = 1.0;
    if (contrast != 0) {
        sat_factor = 1 - contrast / 750.0;
    }
    sat_factor = sat_factor * (sat + 100.0) / 100.0;

    if (mode == MODE_BLENDERAGX) {
        rgb = mult_f3_f33(rgb, AgXInsetMatrix_t);
    }
    
    const float target_slope = 1.0;
    float res[3] = tonemap(rgb[0], rgb[1], rgb[2],
                           target_slope, white_point, black_point,
                           mid_gray_in, mid_gray_out);

    if (contrast != 0) {
        const float pivot = mid_gray_in / white_point;
        const float c = pow(fabs(contrast / 100.0), 1.5) * 16.0;
        const float b = ite(contrast > 0, 1 + c, 1.0 / (1 + c));
        const float a = log((exp(log(b) * pivot) - 1) / (b - 1)) / log(pivot);
        for (int i = 0; i < 3; i = i+1) {
            res[i] = display_contrast(res[i], a, b, white_point, black_point);
        }
    }

    if (mode == MODE_BLENDERAGX) {
        res = mult_f3_f33(res, AgXOutsetMatrix_t);
        if (hue_preservation > 0 || sat_factor != 1.0) {
            float hsl[3] = to_hsl(res[0], res[1], res[2], 1);
            if (hue_preservation > 0) {
                float hue = to_hsl(r, g, b, 1)[0];
                hsl[0] = intp(hue_preservation, hue, hsl[0]);
            }
            hsl[1] = hsl[1] * sat_factor;
            res = to_rgb(hsl, 1);
        }
    } else {
        res = creative_hue_sat_tweaks(1.0 - hue_preservation,
                                      sat_factor, r, g, b,
                                      white_point, res, fmin(mode, 1));
    }

    rout = clamp(res[0], 0, white_point);
    gout = clamp(res[1], 0, white_point);
    bout = clamp(res[2], 0, white_point);
}
