// @ART-colorspace: "rec2020"
// @ART-label: "$CTL_LOG_CONVERSION;Log conversion"
// @ART-lut: -1

import "_artlib";

// Constants
const float arri_a = (pow(2.0, 18.0) - 16.0) / 117.45;
const float arri_b = (1023.0 - 95.0) / 1023.0;
const float arri_c = 95.0 / 1023.0;
const float arri_s = (7 * log(2) * pow(2.0, 7 - 14 * arri_c / arri_b)) / (arri_a * arri_b);
const float arri_t = (pow(2.0, 14.0 * (-arri_c / arri_b) + 6.0) - 64.0) / arri_a;

// LogC4 Curve Encoding Function
float relativeSceneLinearToNormalizedLogC4( float x)
{
    if (x < arri_t) {
        return (x - arri_t) / arri_s;
    }

    return (log2( arri_a * x + 64.0) - 6.0) / 14.0 * arri_b + arri_c;
}

// LogC4 Curve Decoding Function
float normalizedLogC4ToRelativeSceneLinear( float x)
{
    if (x < 0.0) {
        return x * arri_s + arri_t;
    }

    float p = 14.0 * (x - arri_c) / arri_b + 6.0;
    return (pow(2.0, p) - 64.0) / arri_a;
}


const float red_a = 0.224282;
const float red_b = 155.975327;
const float red_c = 0.01;
const float red_g = 15.1927;

float log3G10Inverse(float x)
{
    if (x < 0.0) {
        return (x/red_g)-red_c;
    }
    const float out = (pow(10.0,x/red_a)-1.0) / red_b;
    return out - red_c;
}

float log3G10(float xx)
{
    float x = xx + red_c;
    if (x < 0.0) {
        return x*red_g;
    }
    const float out = red_a*log10((x*red_b)+1.0);
    return out;
}


float slog3(float x)
{
    if (x >= 0.01125000) {
        return (420.0 + log10((x + 0.01) / (0.18 + 0.01)) * 261.5) / 1023.0;
    } else {
        return (x * (171.2102946929 - 95.0)/0.01125000 + 95.0) / 1023.0;
    }
}


float slog3inv(float x)
{
    if (x >= 171.2102946929 / 1023.0) {
        return pow(10.0, ((x * 1023.0 - 420.0) / 261.5)) * (0.18 + 0.01) - 0.01;
    } else {
        return (x * 1023.0 - 95.0) * 0.01125000 / (171.2102946929 - 95.0);
    }
}


const float fuji_a = 5.555556;
const float fuji_b = 0.064829;
const float fuji_c = 0.245281;
const float fuji_d = 0.384316;
const float fuji_e = 8.799461;
const float fuji_f = 0.092864;
const float fuji_cut1 = 0.000889;
const float fuji_cut2 = 0.100686685370811;

float flog2(float x)
{
    if (x >= fuji_cut1) {
        return fuji_c * log10(fuji_a * x + fuji_b) + fuji_d;
    } else {
        return fuji_e * x + fuji_f;
    }
}


float flog2inv(float x)
{
    if (x >= fuji_cut2) {
        return pow(10.0, ((x - fuji_d) / fuji_c)) / fuji_a - fuji_b / fuji_a;
    } else {
        return (x - fuji_f) / fuji_e;
    }
}

const float AgxMinEv = -12.47393;
const float AgxMaxEv = 4.026069; 

float agx_log(float x)
{
    float y = log2(x);
    y = (y - AgxMinEv) / (AgxMaxEv - AgxMinEv);
    return y;//clamp(y, 0, 1);
}


float agx_log_inv(float x)
{
    //return pow(fmax(0.0, x), 2.2);
    float y = x * (AgxMaxEv - AgxMinEv) + AgxMinEv;
    return pow(2, y);
}


float ACEScct_to_lin(float x)
{
    if (x <= 0.0078125) {
        return 10.5402377416545 * x + 0.0729055341958355;
    } else {
        return (log2(x) + 9.72) / 17.52;
    }
}


float lin_to_ACEScct(float x)
{
    if (x <= 0.15525114155) {
        return (x - 0.0729055341958355) / 10.5402377416545;
    } else {
        return pow(2, x * 17.52 - 9.72);
    }
}


// @ART-param: ["direction", "$CTL_DIRECTION;Direction", ["$CTL_FORWARD_LIN_LOG;Forward (linear to log)", "$CTL_FORWARD_LOG_LIN;Inverse (log to linear)"], 0]
// @ART-param: ["mode", "$CTL_LOG_CURVE;Log curve", ["ACEScct", "ARRI LogC4", "RED Log3G10", "Sony Slog3", "Fujifilm F-Log2", "AgX log2"], 0]
void ART_main(varying float r, varying float g, varying float b,
              output varying float rout,
              output varying float gout,
              output varying float bout,
              int direction, int mode)
{
    float rgb[3] = { r, g, b };
    const bool invert = (direction == 1);
    if (mode == 1) {
        if (invert) {
            for (int i = 0; i < 3; i = i+1) {
                rgb[i] = normalizedLogC4ToRelativeSceneLinear(rgb[i]);
            }
        } else {
            for (int i = 0; i < 3; i = i+1) {
                rgb[i] = relativeSceneLinearToNormalizedLogC4(rgb[i]);
            }
        }
    } else if (mode == 2) {
        if (invert) {
            for (int i = 0; i < 3; i = i+1) {
                rgb[i] = log3G10Inverse(rgb[i]);
            }
        } else {
            for (int i = 0; i < 3; i = i+1) {
                rgb[i] = log3G10(rgb[i]);
            }
        }
    } else if (mode == 3) {
        if (invert) {
            for (int i = 0; i < 3; i = i+1) {
                rgb[i] = slog3inv(rgb[i]);
            }
        } else {
            for (int i = 0; i < 3; i = i+1) {
                rgb[i] = slog3(rgb[i]);
            }
        }
    } else if (mode == 4) {
        if (invert) {
            for (int i = 0; i < 3; i = i+1) {
                rgb[i] = flog2inv(rgb[i]);
            }
        } else {
            for (int i = 0; i < 3; i = i+1) {
                rgb[i] = flog2(rgb[i]);
            }
        }
    } else if (mode == 5) {
        if (invert) {
            for (int i = 0; i < 3; i = i+1) {
                rgb[i] = agx_log_inv(rgb[i]);
            }
        } else {
            for (int i = 0; i < 3; i = i+1) {
                rgb[i] = agx_log(rgb[i]);
            }
        }
    } else {
        if (invert) {
            for (int i = 0; i < 3; i = i+1) {
                rgb[i] = lin_to_ACEScct(rgb[i]);
            }
        } else {
            for (int i = 0; i < 3; i = i+1) {
                rgb[i] = ACEScct_to_lin(rgb[i]);
            }
        }
    }
    rout = rgb[0];
    gout = rgb[1];
    bout = rgb[2];
}
