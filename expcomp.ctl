// @ART-label: "$CTL_EXPOSURE_COMPENSATION;Exposure compensation"
// @ART-lut: -1
// 
// @ART-param: ["ev", "$CTL_EXPOSURE_COMPENSATION_EV;Exposure compensation (Ev)", -10, 10, 0, 0.01]

void ART_main(varying float r, varying float g, varying float b,
              output varying float rout,
              output varying float gout,
              output varying float bout,
              float ev)
{
    const float f = pow(2.0, ev);
    rout = r * f;
    gout = g * f;
    bout = b * f;
}
