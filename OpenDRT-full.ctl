/* OpenDRT v1.0.0 -------------------------------------------------


  Written by Jed Smith
  https://github.com/jedypod/open-display-transform
  License: GPLv3
  -------------------------------------------------*/

/* // Tonescale Parameters */
/* DEFINE_UI_PARAMS(Lp, Lp, DCTLUI_SLIDER_FLOAT, 100.0, 100.0, 1000.0, 0.0) */
/* DEFINE_UI_PARAMS(Lg, Lg, DCTLUI_SLIDER_FLOAT, 10.0, 3.0, 30.0, 0.0) */
/* DEFINE_UI_PARAMS(Lgb, Lg boost, DCTLUI_SLIDER_FLOAT, 0.12, 0.0, 0.5, 0.0) */
/* DEFINE_UI_PARAMS(p, contrast, DCTLUI_SLIDER_FLOAT, 1.4, 1.0, 2.0, 0.0) */
/* DEFINE_UI_PARAMS(toe, toe, DCTLUI_SLIDER_FLOAT, 0.001, 0.0, 0.02, 0.0) */

/* // Color Parameters */
/* DEFINE_UI_PARAMS(pc_p0, purity compress low, DCTLUI_SLIDER_FLOAT, 0.4, 0.0, 1.0, 0.0) */
/* DEFINE_UI_PARAMS(pc_p1, purity compress high, DCTLUI_SLIDER_FLOAT, 0.8, 0.0, 1.0, 0.0) */
/* DEFINE_UI_PARAMS(pb_m0, purity low, DCTLUI_SLIDER_FLOAT, 1.3, 1.0, 2.0, 0.0) */
/* DEFINE_UI_PARAMS(pb_m1, purity high, DCTLUI_SLIDER_FLOAT, 0.5, 0.0, 1.0, 0.0) */
/* DEFINE_UI_PARAMS(base_look, base look, DCTLUI_CHECK_BOX, 0) */

/* // Encoding / IO */
/* DEFINE_UI_PARAMS(in_gamut, in gamut, DCTLUI_COMBO_BOX, 15, {i_xyz, i_ap0, i_ap1, i_p3d65, i_rec2020, i_rec709, i_awg3, i_awg4, i_rwg, i_sgamut3, i_sgamut3cine, i_vgamut, i_bmdwg, i_egamut, i_egamut2, i_davinciwg}, {XYZ, ACES 2065-1, ACEScg, P3D65, Rec.2020, Rec.709, Arri Wide Gamut 3, Arri Wide Gamut 4, Red Wide Gamut RGB, Sony SGamut3, Sony SGamut3Cine, Panasonic V-Gamut, Blackmagic Wide Gamut, Filmlight E-Gamut, Filmlight E-Gamut2, DaVinci Wide Gamut}) */
/* DEFINE_UI_PARAMS(in_oetf, in transfer function, DCTLUI_COMBO_BOX, 0, {ioetf_linear, ioetf_davinci_intermediate, ioetf_filmlight_tlog, ioetf_arri_logc3, ioetf_arri_logc4, ioetf_panasonic_vlog, ioetf_sony_slog3, ioetf_fuji_flog}, {Linear, Davinci Intermediate, Filmlight T-Log, Arri LogC3, Arri LogC4, Panasonic V-Log, Sony S-Log3, Fuji F-Log}) */
/* DEFINE_UI_PARAMS(display_gamut, display gamut, DCTLUI_COMBO_BOX, 0, {Rec709, P3D65, Rec2020}, {Rec.709, P3 D65, Rec.2020}) */
/* DEFINE_UI_PARAMS(EOTF, display eotf, DCTLUI_COMBO_BOX, 2, {lin, srgb, rec1886, dci, pq, hlg}, {Linear, 2.2 Power sRGB Display, 2.4 Power Rec .1886, 2.6 Power DCI, ST 2084 PQ, HLG}) */


float fmin(float a, float b)
{
    if (a < b) {
        return a;
    } else {
        return b;
    }
}


float fmax(float a, float b)
{
    if (a > b) {
        return a;
    } else {
        return b;
    }
}


float ite(bool cond, float t, float e)
{
    if (cond) {
        return t;
    } else {
        return e;
    }
}


const float log2_val = log(2);

float log2(float x)
{
    float y = x;
    if (y < 0) {
        y = 1e-20;
    }
    return log(y) / log2_val;
}

const float SQRT3 = 1.73205080756887729353;
const float PI =  3.14159265358979323846;

struct float2 {
    float x;
    float y;
};

struct float3 {
    float x;
    float y;
    float z;
};

struct float3x3 {
    float3 x;
    float3 y;
    float3 z;
};

float2 make_float2(float a, float b)
{
    float2 res = { a, b };
    return res;
}

float3 make_float3(float a, float b, float c)
{
    float3 res = { a, b, c };
    return res;
}

// Helper function to create a float3x3
float3x3 make_float3x3(float3 a, float3 b, float3 c)
{
    float3x3 d;
    d.x = a;
    d.y = b;
    d.z = c;
    return d;
}


float3 mul_f3f(float3 a, float b) { return make_float3(a.x * b, a.y * b, a.z * b); }
float3 add_f3f(float3 a, float b) { return make_float3(a.x + b, a.y + b, a.z + b); }
float3 add_ff3(float a, float3 b) { return add_f3f(b, a); }
float3 sub_f3f(float3 a, float b) { return make_float3(a.x - b, a.y - b, a.z - b); }
float3 sub_ff3(float a, float3 b) { return make_float3(a - b.x, a - b.y, a - b.z); }
float3 add_f3f3(float3 a, float3 b) { return make_float3(a.x + b.x, a.y + b.y, a.z + b.z); }

float clampf(float x, float mn, float mx)
{
    return fmin(fmax(x, mn), mx);
}

// Gamut Conversion Matrices
// Input gamut conversion matrices
const float3x3 matrix_ap0_to_xyz = make_float3x3(make_float3(0.938630948750273197, -0.00574192055037397141, 0.017566898851772296), make_float3(0.338093594922021567, 0.72721390281143572, -0.0653074977334571899), make_float3(0.000723121511341165988, 0.000818441849244731985, 1.08751618739929268));
const float3x3 matrix_ap1_to_xyz = make_float3x3(make_float3(0.652418717671912951, 0.127179925537538263, 0.170857283842220459), make_float3(0.268064059194271287, 0.672464478992617742, 0.0594714618131108388), make_float3(-0.0054699285104975676, 0.00518279997697511721, 1.08934487929340107));
const float3x3 matrix_rec2020_to_xyz = make_float3x3(make_float3(0.636958048301290991, 0.144616903586208406, 0.168880975164172054), make_float3(0.26270021201126692, 0.677998071518871148, 0.0593017164698619384), make_float3(4.9999999999999999e-17, 0.0280726930490874452, 1.06098505771079066));
const float3x3 matrix_arriwg3_to_xyz = make_float3x3(make_float3(0.638007619284, 0.214703856337, 0.097744451431), make_float3(0.291953779, 0.823841041511, -0.11579482051), make_float3(0.002798279032, -0.067034235689, 1.15329370742));
const float3x3 matrix_arriwg4_to_xyz = make_float3x3(make_float3(0.704858320407231953, 0.129760295170463003, 0.115837311473976537), make_float3(0.254524176404026969, 0.781477732712002049, -0.0360019091160290391), make_float3(0.0, 0.0, 1.08905775075987843));
const float3x3 matrix_redwg_to_xyz = make_float3x3(make_float3(0.735275245905858799, 0.0686094106139610721, 0.14657127053185201), make_float3(0.286694099499934962, 0.842979134016975662, -0.129673233516910319), make_float3(-0.0796808568783676785, -0.347343216994429771, 1.51608182463267593));
const float3x3 matrix_sonysgamut3_to_xyz = make_float3x3(make_float3(0.706482713192318812, 0.12880104979055762, 0.115172164068795255), make_float3(0.270979670813492168, 0.786606411220905466, -0.0575860820343976273), make_float3(-0.00967784538619615754, 0.00460003749251991934, 1.09413555865355483));
const float3x3 matrix_sonysgamut3cine_to_xyz = make_float3x3(make_float3(0.599083920758327171, 0.248925516115423628, 0.102446490177920776), make_float3(0.215075820115587457, 0.88506850174372842, -0.100144321859315821), make_float3(-0.0320658495445057951, -0.0276583906794915374, 1.1487819909838759));
const float3x3 matrix_vgamut_to_xyz = make_float3x3(make_float3(0.679644469878, 0.15221141244, 0.118600044733), make_float3(0.26068555009, 0.77489446333, -0.03558001342), make_float3(-0.009310198218, -0.004612467044, 1.10298041602));
const float3x3 matrix_bmdwg_to_xyz = make_float3x3(make_float3(0.606538368282783846, 0.220412735329269888, 0.12350482343961787), make_float3(0.2679929400567444, 0.832748409123375777, -0.100741349180120274), make_float3(-0.029442554160109307, -0.0866124302772565829, 1.20511273519724438));
const float3x3 matrix_egamut_to_xyz = make_float3x3(make_float3(0.705396850087770755, 0.164041328309919021, 0.0810177486539819941), make_float3(0.280130724091105898, 0.820206641549595106, -0.100337365640700782), make_float3(-0.103781511569163279, -0.0729072570266306313, 1.26574651935567273));
const float3x3 matrix_egamut2_to_xyz = make_float3x3(make_float3(0.736477700183697404, 0.130739651086660136, 0.0832385757813140781), make_float3(0.275069984405959256, 0.828017790215514138, -0.103087774621473588), make_float3(-0.124225154247852534, -0.0871597673911067433, 1.30044267239883782));
const float3x3 matrix_davinciwg_to_xyz = make_float3x3(make_float3(0.700622392093671609, 0.148774815123196763, 0.101058719834803246), make_float3(0.274118510906649016, 0.873631895940436665, -0.147750406847085763), make_float3(-0.0989629128832311411, -0.137895325075543307, 1.32591598871865268));

// P3D65 to XYZ D65
const float3x3 matrix_p3d65_to_xyz = make_float3x3(make_float3(0.486570948648216151, 0.265667693169093, 0.198217285234362467), make_float3(0.228974564069748754, 0.691738521836506193, 0.079286914093744984), make_float3(-4.00000000000000029e-17, 0.0451133818589026167, 1.04394436890097575));
// XYZ D65 to P3D65
const float3x3 matrix_xyz_to_p3d65 = make_float3x3(make_float3(2.49349691194142542, -0.93138361791912383, -0.402710784450716841), make_float3(-0.829488969561574696, 1.76266406031834655, 0.0236246858419435941), make_float3(0.0358458302437844531, -0.0761723892680418041, 0.956884524007687309));
// Rec709 to XYZ D65
const float3x3 matrix_rec709_to_xyz = make_float3x3(make_float3(0.412390799265959229, 0.357584339383878125, 0.180480788401834347), make_float3(0.212639005871510217, 0.71516867876775625, 0.0721923153607337414), make_float3(0.0193308187155918181, 0.119194779794626018, 0.950532152249661033));
// XYZ D65 to Rec709
const float3x3 matrix_xyz_to_rec709 = make_float3x3(make_float3(3.24096994190452348, -1.53738317757009435, -0.498610760293003552), make_float3(-0.969243636280879506, 1.87596750150771996, 0.0415550574071755843), make_float3(0.0556300796969936354, -0.20397695888897649, 1.05697151424287816));
// P3D65 to Rec2020
const float3x3 matrix_p3_to_rec2020 = make_float3x3(make_float3(0.753833034361722221, 0.198597369052616435, 0.0475695965856618441), make_float3(0.0457438489653582137, 0.9417772198116936, 0.0124789312229481135), make_float3(-0.0012103403545183941, 0.0176017173010899926, 0.983608623053428777));
// P3DCI to XYZ DCI (NPM Matrix)
const float3x3 matrix_p3dci_to_xyz = make_float3x3(make_float3(0.445169815564552429, 0.27713440920677751, 0.172282669815564504), make_float3(0.209491677912730545, 0.721595254161043309, 0.0689130679262257989), make_float3(-3.59999999999999995e-17, 0.0470605600539811264, 0.9073553943619731));

const float3x3 matrix_xyz_to_rec2020 = make_float3x3(make_float3(1.71665118797, -0.355670783776, -0.253366281374), make_float3(-0.666684351832, 1.61648123664, 0.015768545814), make_float3(0.017639857445, -0.042770613258, 0.942103121235));

/******************************************************************
  CAT02 Chromatic Adaptation Matrices
 ******************************************************************/

// DCI to D93 : [0.314, 0.351] to [0.283, 0.297]
const float3x3 matrix_cat_dci_to_d93 = make_float3x3(make_float3(0.965685009956359863, 0.00183745240792632103, 0.0912967324256896973), make_float3(0.000514572137035429044, 0.965166747570037842, 0.036014653742313385), make_float3(0.00154250487685203596, 0.00702651776373386383, 1.47287476062774658));
// DCI to D75 : [0.314, 0.351] to [0.29903, 0.31488]
const float3x3 matrix_cat_dci_to_d75 = make_float3x3(make_float3(0.990120768547058105, 0.0151389474049210548, 0.0511047691106796265), make_float3(0.0102197211235761642, 0.971718132495880127, 0.0200536623597145081), make_float3(0.000743072712793946049, 0.0042176349088549614, 1.27959656715393066));
// DCI to D65 : [0.314, 0.351] to [0.3127, 0.329]
const float3x3 matrix_cat_dci_to_d65 = make_float3x3(make_float3(1.00951600074768066, 0.0269675441086292267, 0.0213620811700820923), make_float3(0.0187991037964820862, 0.975330352783203125, 0.0082273334264755249), make_float3(0.000134543282911180989, 0.00217903498560190201, 1.138663649559021));
// DCI to D60 : [0.314, 0.351] to [0.32162624, 0.337737]
const float3x3 matrix_cat_dci_to_d60 = make_float3x3(make_float3(1.02159523963928223, 0.034848678857088089, 0.00371252000331878705), make_float3(0.0244968775659799576, 0.976937234401702881, 0.00120301544666290305), make_float3(-0.00023391586728393999, 0.000986687839031219049, 1.05594265460968018));
// DCI to D55 : [0.314, 0.351] to [0.33243, 0.34744]
const float3x3 matrix_cat_dci_to_d55 = make_float3x3(make_float3(1.03594577312469482, 0.0450937561690807343, -0.0157573819160461426), make_float3(0.0318740680813789368, 0.977744519710540771, -0.00655744969844818115), make_float3(-0.000653609400615095984, -0.000297372229397297014, 0.966327786445617676));
// DCI to D50 : [0.314, 0.351] to [0.3457, 0.3585]
const float3x3 matrix_cat_dci_to_d50 = make_float3x3(make_float3(1.05306875705718994, 0.0581297315657138824, -0.0376100838184356689), make_float3(0.0412359423935413361, 0.977693676948547363, -0.0152792222797870636), make_float3(-0.00113777676597237609, -0.00170759297907352404, 0.867368340492248535));

// D65 to D93 : [0.3127, 0.329] to [0.283, 0.297]
const float3x3 matrix_cat_d65_to_d93 = make_float3x3(make_float3(0.95703423023223877, -0.0247171502560377121, 0.0624028593301773071), make_float3(-0.0179296955466270447, 0.990019857883453369, 0.0248119533061981201), make_float3(0.00127589143812656403, 0.00427919067442417058, 1.29345715045928955));
// D65 to D75 : [0.3127, 0.329] to [0.29903, 0.31488]
const float3x3 matrix_cat_d65_to_d75 = make_float3x3(make_float3(0.981001079082489014, -0.0116619253531098366, 0.0265614092350006104), make_float3(-0.00843488052487373352, 0.996506094932556152, 0.0105696544051170349), make_float3(0.000552809564396739006, 0.00179840810596942902, 1.12374722957611084));
// D65 to D60 : [0.3127, 0.329] to [0.32162624, 0.337737]
const float3x3 matrix_cat_d65_to_d60 = make_float3x3(make_float3(1.01182246208190918, 0.00778879318386316299, -0.0157783031463623047), make_float3(0.00561682833358645439, 1.00150644779205322, -0.00628517568111419678), make_float3(-0.000335735734552145004, -0.0010509500280022619, 0.927366673946380615));
// D65 to D55 : [0.3127, 0.329] to [0.33243, 0.34744]
const float3x3 matrix_cat_d65_to_d55 = make_float3x3(make_float3(1.02585089206695557, 0.0179439820349216461, -0.0332137793302536011), make_float3(0.0129133854061365128, 1.00214779376983643, -0.0132421031594276428), make_float3(-0.000719940289855003032, -0.00218106806278228803, 0.84868013858795166));
// D65 to D50 : [0.3127, 0.329] to [0.3457, 0.3585]
const float3x3 matrix_cat_d65_to_d50 = make_float3x3(make_float3(1.04257404804229736, 0.03089117631316185, -0.052812620997428894), make_float3(0.0221935361623764038, 1.00185668468475342, -0.0210737623274326324), make_float3(-0.00116488314233720303, -0.00342052709311246915, 0.761789083480834961));
// D65 to DCI-P3 : [0.3127, 0.329] to [0.314, 0.351]
const float3x3 matrix_cat_d65_to_dci = make_float3x3(make_float3(0.991085588932037354, -0.0273622870445251465, -0.0183956623077392578), make_float3(-0.0191021915525197983, 1.02583777904510498, -0.00705372542142868042), make_float3(-8.05503223091359977e-05, -0.00195988826453685804, 0.878238439559936523));

// D60 to D93 : [0.32162624, 0.337737] to [0.283, 0.297]
const float3x3 matrix_cat_d60_to_d93 = make_float3x3(make_float3(0.946056902408599854, -0.0319503024220466614, 0.0831701457500457764), make_float3(-0.0231979694217443466, 0.988745808601379395, 0.0330617502331733704), make_float3(0.00169203430414199807, 0.00572328735142946243, 1.39483106136322021));
// D60 to D75 : [0.32162624, 0.337737] to [0.29903, 0.31488]
const float3x3 matrix_cat_d60_to_d75 = make_float3x3(make_float3(0.969659984111785889, -0.019138311967253685, 0.0450099557638168335), make_float3(-0.0138545772060751915, 0.995133817195892334, 0.0179062262177467346), make_float3(0.000931452261283994046, 0.00306008197367191315, 1.21179807186126709));
// D60 to D65 : [0.32162624, 0.337737] to [0.3127, 0.329]
const float3x3 matrix_cat_d60_to_d65 = make_float3x3(make_float3(0.988363921642303467, -0.00766910053789615631, 0.0167641639709472656), make_float3(-0.0055409618653357029, 0.998546123504638672, 0.00667332112789154139), make_float3(0.000351537019014359008, 0.00112883746623992898, 1.07833576202392578));
// D60 to D55 : [0.32162624, 0.337737] to [0.33243, 0.34744]
const float3x3 matrix_cat_d60_to_d55 = make_float3x3(make_float3(1.01380288600921631, 0.0100131509825587273, -0.018498346209526062), make_float3(0.00720565160736441612, 1.00057685375213623, -0.00737529993057250977), make_float3(-0.000401133671402930997, -0.00121434964239597299, 0.915135681629180908));
// D60 to D50 : [0.32162624, 0.337737] to [0.3457, 0.3585]
const float3x3 matrix_cat_d60_to_d50 = make_float3x3(make_float3(1.03025269508361816, 0.0227910466492176056, -0.0392656922340393066), make_float3(0.0163766480982303619, 1.00020599365234375, -0.0156668238341808319), make_float3(-0.000864576781168579947, -0.00254668481647968292, 0.821422040462493896));

/* Math helper functions ----------------------------*/

// Return identity 3x3 matrix
float3x3 identity() {
  return make_float3x3(make_float3(1.0, 0.0, 0.0), make_float3(0.0, 1.0, 0.0), make_float3(0.0, 0.0, 1.0));
}

// Multiply 3x3 matrix m and float3 vector v
float3 vdot(float3x3 m, float3 v) {
  return make_float3(m.x.x*v.x + m.x.y*v.y + m.x.z*v.z, m.y.x*v.x + m.y.y*v.y + m.y.z*v.z, m.z.x*v.x + m.z.y*v.y + m.z.z*v.z);
}

// Safe division of float a by float b
float sdivf(float a, float b) {
  if (b == 0.0) return 0.0;
  else return a/b;
}

// Safe division of float3 a by float b
float3 sdivf3(float3 a, float b) {
  return make_float3(sdivf(a.x, b), sdivf(a.y, b), sdivf(a.z, b));
}

// Safe element-wise division of float3 a by float3 b
float3 sdivf33(float3 a, float3 b) {
  return make_float3(sdivf(a.x, b.x), sdivf(a.y, b.y), sdivf(a.z, b.z));
}

// Safe power function raising float a to power float b
float spowf(float a, float b) {
  if (a <= 0.0) return a;
  else return pow(a, b);
}

// Return the hypot or vector length of float2 v
float hypotf2(float2 v) { return sqrt(fmax(0.0, v.x*v.x + v.y*v.y)); }

// Safe power function raising float3 a to power float b
float3 spowf3(float3 a, float b) {
  return make_float3(spowf(a.x, b), spowf(a.y, b), spowf(a.z, b));
}

// Return the hypot or length of float3 a
float hypotf3(float3 v) { return sqrt(fmax(0.0, v.x*v.x + v.y*v.y + v.z*v.z)); }

// Return the min of float3 a
float fmaxf3(float3 a) { return fmax(a.x, fmax(a.y, a.z)); }

// Return the max of float3 a
float fminf3(float3 a) { return fmin(a.x, fmin(a.y, a.z)); }

// Clamp float3 a to max value mx
float3 clampmaxf3(float3 a, float mx) { return make_float3(fmin(a.x, mx), fmin(a.y, mx), fmin(a.z, mx)); }

// Clamp float3 a to min value mn
float3 clampminf3(float3 a, float mn) { return make_float3(fmax(a.x, mn), fmax(a.y, mn), fmax(a.z, mn)); }

// Clamp each component of float3 a to be between float mn and float mx
float3 clampf3(float3 a, float mn, float mx) { 
  return make_float3(fmin(fmax(a.x, mn), mx), fmin(fmax(a.y, mn), mx), fmin(fmax(a.z, mn), mx));
}


/* OETF Linearization Transfer Functions ---------------------------------------- */

/* float oetf_davinci_intermediate(float x) { */
/*     return ite(x <= 0.02740668, x/10.44426855, exp2(x/0.07329248 - 7.0) - 0.0075); */
/* } */

/* float oetf_filmlight_tlog(float x) { */
/*     return ite(x < 0.075, (x-0.075)/16.184376489665897, exp((x - 0.5520126568606655)/0.09232902596577353) - 0.0057048244042473785); */
/* } */
/* float oetf_arri_logc3(float x) { */
/*     return ite(x < 5.367655*0.010591 + 0.092809, (x - 0.092809)/5.367655, (exp10((x - 0.385537)/0.247190) - 0.052272)/5.555556); */
/* } */

/* float oetf_arri_logc4(float x) { */
/*     return ite(x < -0.7774983977293537, x*0.3033266726886969 - 0.7774983977293537, (exp2(14.0*(x - 0.09286412512218964)/0.9071358748778103 + 6.0) - 64.0)/2231.8263090676883); */
/* } */

/* float oetf_panasonic_vlog(float x) { */
/*     return ite(x < 0.181, (x - 0.125)/5.6, exp10((x - 0.598206)/0.241514) - 0.00873); */
/* } */

/* float oetf_sony_slog3(float x) { */
/*     return ite(x < 171.2102946929/1023.0, (x*1023.0 - 95.0)*0.01125/(171.2102946929 - 95.0), (exp10(((x*1023.0 - 420.0)/261.5))*(0.18 + 0.01) - 0.01)); */
/* } */

/* float oetf_fujifilm_flog(float x) { */
/*     return ite(x < 0.1005377752, (x - 0.092864)/8.735631, (exp10(((x - 0.790453)/0.344676))/0.555556 - 0.009468/0.555556)); */
/* } */


/* float3 linearize(float3 rgb, int tf) { */
/*   if (tf == 0) { // Linear */
/*     return rgb; */
/*   } else if (tf == 1) { // Davinci Intermediate */
/*     rgb.x = oetf_davinci_intermediate(rgb.x); */
/*     rgb.y = oetf_davinci_intermediate(rgb.y); */
/*     rgb.z = oetf_davinci_intermediate(rgb.z); */
/*   } else if (tf == 2) { // Filmlight T-Log */
/*     rgb.x = oetf_filmlight_tlog(rgb.x); */
/*     rgb.y = oetf_filmlight_tlog(rgb.y); */
/*     rgb.z = oetf_filmlight_tlog(rgb.z); */
/*   } else if (tf == 3) { // Arri LogC3 */
/*     rgb.x = oetf_arri_logc3(rgb.x); */
/*     rgb.y = oetf_arri_logc3(rgb.y); */
/*     rgb.z = oetf_arri_logc3(rgb.z); */
/*   } else if (tf == 4) { // Arri LogC4 */
/*     rgb.x = oetf_arri_logc4(rgb.x); */
/*     rgb.y = oetf_arri_logc4(rgb.y); */
/*     rgb.z = oetf_arri_logc4(rgb.z); */
/*   } else if (tf == 5) { // Panasonic V-Log */
/*     rgb.x = oetf_panasonic_vlog(rgb.x); */
/*     rgb.y = oetf_panasonic_vlog(rgb.y); */
/*     rgb.z = oetf_panasonic_vlog(rgb.z); */
/*   } else if (tf == 6) { // Sony S-Log3 */
/*     rgb.x = oetf_sony_slog3(rgb.x); */
/*     rgb.y = oetf_sony_slog3(rgb.y); */
/*     rgb.z = oetf_sony_slog3(rgb.z); */
/*   } else if (tf == 7) { // Fuji F-Log */
/*     rgb.x = oetf_fujifilm_flog(rgb.x); */
/*     rgb.y = oetf_fujifilm_flog(rgb.y); */
/*     rgb.z = oetf_fujifilm_flog(rgb.z); */
/*   } */
/*   return rgb; */
/* } */



/* /\* EOTF Transfer Functions ---------------------------------------- *\/ */

/* float3 eotf_hlg(float3 in_rgb, int inverse) { */
/*   // Aply the HLG Forward or Inverse EOTF. Implements the full ambient surround illumination model */
/*   // ITU-R Rec BT.2100-2 https://www.itu.int/rec/R-REC-BT.2100 */
/*   // ITU-R Rep BT.2390-8: https://www.itu.int/pub/R-REP-BT.2390 */
/*   // Perceptual Quantiser (PQ) to Hybrid Log-Gamma (HLG) Transcoding: https://www.bbc.co.uk/rd/sites/50335f370b5c262af000004/assets/592eea8006d63e5e520090d/BBC_HDRTV_PQ_HLG_Transcode_v2.pdf */

/*     float3 rgb = in_rgb; */
    
/*   const float HLG_Lw = 1000.0; */
/*   // const float HLG_Lb = 0.0; */
/*   const float HLG_Ls = 5.0; */
/*   const float h_a = 0.17883277; */
/*   const float h_b = 1.0 - 4.0*0.17883277; */
/*   const float h_c = 0.5 - h_a*log(4.0*h_a); */
/*   const float h_g = 1.2*spowf(1.111, log2(HLG_Lw/1000.0))*spowf(0.98, log2(fmax(1e-6, HLG_Ls)/5.0)); */
/*   if (inverse == 1) { */
/*     float Yd = 0.2627*rgb.x + 0.6780*rgb.y + 0.0593*rgb.z; */
/*     // HLG Inverse OOTF */
/*     rgb = rgb*spowf(Yd, (1.0 - h_g)/h_g); */
/*     // HLG OETF */
/*     rgb.x = ite(rgb.x <= 1.0/12.0, sqrt(3.0*rgb.x), h_a*log(12.0*rgb.x - h_b) + h_c); */
/*     rgb.y = ite(rgb.y <= 1.0/12.0, sqrt(3.0*rgb.y), h_a*log(12.0*rgb.y - h_b) + h_c); */
/*     rgb.z = ite(rgb.z <= 1.0/12.0, sqrt(3.0*rgb.z), h_a*log(12.0*rgb.z - h_b) + h_c); */
/*   } else { */
/*     // HLG Inverse OETF */
/*     rgb.x = ite(rgb.x <= 0.5, rgb.x*rgb.x/3.0, (exp((rgb.x - h_c)/h_a) + h_b)/12.0); */
/*     rgb.y = ite(rgb.y <= 0.5, rgb.y*rgb.y/3.0, (exp((rgb.y - h_c)/h_a) + h_b)/12.0); */
/*     rgb.z = ite(rgb.z <= 0.5, rgb.z*rgb.z/3.0, (exp((rgb.z - h_c)/h_a) + h_b)/12.0); */
/*     // HLG OOTF */
/*     float Ys = 0.2627*rgb.x + 0.6780*rgb.y + 0.0593*rgb.z; */
/*     rgb = rgb*spowf(Ys, h_g - 1.0); */
/*   } */
/*   return rgb; */
/* } */


/* float3 eotf_pq(float3 rgb, int inverse) { */
/*   /\* Apply the ST-2084 PQ Forward or Inverse EOTF */
/*       ITU-R Rec BT.2100-2 https://www.itu.int/rec/R-REC-BT.2100 */
/*       ITU-R Rep BT.2390-9 https://www.itu.int/pub/R-REP-BT.2390 */
/*       Note: in the spec there is a normalization for peak display luminance.  */
/*       For this function we assume the input is already normalized such that 1.0 = 10,000 nits */
/*   *\/ */
  
/*   // const float Lp = 1.0; */
/*   const float m1 = 2610.0/16384.0; */
/*   const float m2 = 2523.0/32.0; */
/*   const float c1 = 107.0/128.0; */
/*   const float c2 = 2413.0/128.0; */
/*   const float c3 = 2392.0/128.0; */

/*   if (inverse == 1) { */
/*     // rgb /= Lp; */
/*     rgb = spowf3(rgb, m1); */
/*     rgb = spowf3((c1 + c2*rgb)/(1.0 + c3*rgb), m2); */
/*   } else { */
/*     rgb = spowf3(rgb, 1.0/m2); */
/*     rgb = spowf3((rgb - c1)/(c2 - c3*rgb), 1.0/m1); */
/*     // rgb *= Lp; */
/*   } */
/*   return rgb; */
/* } */


float compress_hyperbolic_power(float x, float s, float p)
{
  // Simple hyperbolic compression function https://www.desmos.com/calculator/ofwtcmzc3w
  return spowf(x/(x + s), p);
}

float compress_toe_quadratic(float x, float toe, int inv)
{
  // Quadratic toe compress function https://www.desmos.com/calculator/skk8ahmnws
  if (toe == 0.0) return x;
  if (inv == 0) {
    return spowf(x, 2.0)/(x + toe);
  } else {
    return (x + sqrt(x*(4.0*toe + x)))/2.0;
  }
}

float compress_toe_cubic(float x, float m, float w, int inv)
{
  // https://www.desmos.com/calculator/ubgteikoke
  if (m==1.0) return x;
  float x2 = x*x;
  if (inv == 0) {
    return x*(x2 + m*w)/(x2 + w);
  } else {
    float p0 = x2 - 3.0*m*w;
    float p1 = 2.0*x2 + 27.0*w - 9.0*m*w;
    float p2 = pow(sqrt(x2*p1*p1 - 4*p0*p0*p0)/2.0 + x*p1/2.0, 1.0/3.0);
    return p0/(3.0*p2) + p2/3.0 + x/3.0;
  }
}

float complement_power(float x, float p)
{
  return 1.0 - spowf(1.0 - x, 1.0/p);
}

float sigmoid_cubic(float x, float s)
{
  // Simple cubic sigmoid: https://www.desmos.com/calculator/hzgib42en6
  if (x < 0.0 || x > 1.0) return 1.0;
  return 1.0 + s*(1.0 - 3.0*x*x + 2.0*x*x*x);
}

float contrast_high(float x, float p, float pv, float pv_lx, int inv)
{
  // High exposure adjustment with linear extension
  // https://www.desmos.com/calculator/etjgwyrgad
  const float x0 = 0.18*pow(2.0, pv);
  if (x < x0 || p == 1.0) return x;

  const float o = x0 - x0/p;
  const float s0 = pow(x0, 1.0 - p)/p;
  const float x1 = x0*pow(2.0, pv_lx);
  const float k1 = p*s0*pow(x1, p)/x1;
  const float y1 = s0*pow(x1, p) + o;
  if (inv==1) {
      return ite(x > y1, (x - y1)/k1 + x1, pow((x - o)/s0, 1.0/p));
  } else {
      return ite(x > x1, k1*(x - x1) + y1, s0*pow(x, p) + o);
  }
}

float softplus_constraint(float x, float s, float x0, float y0)
{
  // Softplus with (x0, y0) intersection constraint
  // https://www.desmos.com/calculator/doipi4u0ce
  if (x > 10.0*s + y0 || s < 1e-3) return x;
  float m = 1.0;
  if (fabs(y0) > 1e-6) m = exp(y0/s);
  m = m - exp(x0/s);
  return s*log(fmax(0.0, m + exp(x/s)));
}

float softplus(float x, float s)
{
  // Softplus unconstrained
  // https://www.desmos.com/calculator/mr9rmujsmn
  if (x > 10.0*s || s < 1e-4) return x;
  return s*log(fmax(0.0, 1.0 + exp(x/s)));
}

float gauss_window(float x, float w)
{
  // Simple gaussian window https://www.desmos.com/calculator/vhr9hstlyk
  return exp(-x*x/w);
}


float2 opponent(float3 rgb)
{
  // Simple Cyan-Yellow / Green-Magenta opponent space for calculating smooth achromatic distance and hue angles
  return make_float2(rgb.x - rgb.z, rgb.y - (rgb.x + rgb.z)/2.0);
}

float hue_offset(float h, float o)
{
  // Offset hue maintaining 0-2*pi range with modulo
  return fmod(h - o + PI, 2.0*PI) - PI;
}


float3 display_gamut_whitepoint(float3 _rgb, float tsn, float cwp_lm, int display_gamut, int cwp)
{
  // Do final display gamut and creative whitepoint conversion. 
  // Must be done twice for the tonescale overlay, thus a separate function.
  
  // First, convert from P3D65 to XYZ D65
  float3 rgb = vdot(matrix_p3d65_to_xyz, _rgb);

  // Store "neutral" axis for mixing with Creative White Range control
  float3 cwp_neutral = rgb;
  
  float cwp_f = pow(tsn, 2.0*cwp_lm);
  
  if (display_gamut < 3) { // D65 aligned P3 or Rec.709 display gamuts
    if (cwp==0) rgb = vdot(matrix_cat_d65_to_d93, rgb); // D93
    else if (cwp==1) rgb = vdot(matrix_cat_d65_to_d75, rgb); // D75
    // else if (cwp==2) rgb = vdot(matrix_cat_d65_to_d60, rgb); // D65
    else if (cwp==3) rgb = vdot(matrix_cat_d65_to_d60, rgb); // D60
    else if (cwp==4) rgb = vdot(matrix_cat_d65_to_d55, rgb); // D55
    else if (cwp==5) rgb = vdot(matrix_cat_d65_to_d50, rgb); // D50
  } 
  else if (display_gamut == 3) { // P3-D60
    if (cwp==0) rgb = vdot(matrix_cat_d60_to_d93, rgb); // D93
    else if (cwp==1) rgb = vdot(matrix_cat_d60_to_d75, rgb); // D75
    else if (cwp==2) rgb = vdot(matrix_cat_d60_to_d65, rgb); // D65
    // D60
    else if (cwp==4) rgb = vdot(matrix_cat_d60_to_d55, rgb); // D55
    else if (cwp==5) rgb = vdot(matrix_cat_d60_to_d50, rgb); // D50
  } 
  else { // DCI P3 or DCI X'Y'Z'
    // Keep "Neutral" axis as D65, don't want green midtones in P3-DCI container.
    cwp_neutral = vdot(matrix_cat_dci_to_d65, rgb);
    if (cwp==0) rgb = vdot(matrix_cat_dci_to_d93, rgb); // D93
    else if (cwp==1) rgb = vdot(matrix_cat_dci_to_d75, rgb); // D75
    else if (cwp==2) rgb = cwp_neutral;
    else if (cwp==3) rgb = vdot(matrix_cat_dci_to_d60, rgb); // D60
    else if (cwp==4) rgb = vdot(matrix_cat_dci_to_d55, rgb); // D55
    else if (cwp==5) rgb = vdot(matrix_cat_dci_to_d50, rgb); // D50
  }
  
  // Mix between Creative Whitepoint and "neutral" axis with Creative White Range control.
  //rgb = rgb*cwp_f + cwp_neutral*(1.0f - cwp_f);
  rgb = add_f3f3(mul_f3f(rgb, cwp_f), mul_f3f(cwp_neutral, (1.0-cwp_f)));


  // RGB is now aligned to the selected creative white
  // and we can convert back to the final target display gamut
  if (display_gamut == 0) { // Rec.709
    rgb = vdot(matrix_xyz_to_rec709, rgb);
  } 
  else if (display_gamut == 5) { // DCDM X'Y'Z'
    // Convert whitepoint from D65 to DCI
    rgb = vdot(matrix_cat_d65_to_dci, rgb);
  }
  else { // For all others, convert to P3D65
    rgb = vdot(matrix_xyz_to_p3d65, rgb);
  }

  // Post creative whitepoint normalization so that peak luminance does not exceed display maximum.
  // We could calculate this by storing a 1,1,1 value in p3d65 and then normalize by the result through the cat and xyz to rgb matrix. 
  // Instead we use pre-calculated constants to avoid the extra calculations.
    
  /* Pre-calculated normalization factors are inline below
  */

  float cwp_norm = 1.0;
  /* Display Gamut - Rec.709
    rec709 d93: 0.744192699063f
    rec709 d75: 0.873470832146f
    rec709 d60: 0.955936992163f
    rec709 d55: 0.905671332781f
    rec709 d50: 0.850004385027f
  */
  if (display_gamut == 0) { // Rec.709
    if (cwp == 0) cwp_norm = 0.744192699063; // D93
    else if (cwp == 1) cwp_norm = 0.873470832146; // D75
    // else if (cwp == 2) cwp_norm = 1.0f; // D65
    else if (cwp == 3) cwp_norm = 0.955936992163; // D60
    else if (cwp == 4) cwp_norm = 0.905671332781; // D55
    else if (cwp == 5) cwp_norm = 0.850004385027; // D50
  }
  /* Display Gamut - P3D65
    p3d65 d93: 0.762687057298f
    p3d65 d75: 0.884054083328f
    p3d65 d60: 0.964320186739f
    p3d65 d55: 0.923076518860f
    p3d65 d50: 0.876572837784f
  */
  else if (display_gamut == 1 || display_gamut == 2) { // P3D65 or P3 Limited Rec.2020
    if (cwp == 0) cwp_norm = 0.762687057298; // D93
    else if (cwp == 1) cwp_norm = 0.884054083328; // D75
    // else if (cwp == 2) cwp_norm = 1.0f; // D65
    else if (cwp == 3) cwp_norm = 0.964320186739; // D60
    else if (cwp == 4) cwp_norm = 0.923076518860; // D55
    else if (cwp == 5) cwp_norm = 0.876572837784; // D50
  }
  /* Display Gamut - P3D60
    p3d60 d93: 0.704956321013f
    p3d60 d75: 0.816715709816f
    p3d60 d65: 0.923382193663f
    p3d60 d55: 0.956138500287f
    p3d60 d50: 0.906801453023f
  */
  else if (display_gamut == 3) { // P3D60
    if (cwp == 0) cwp_norm = 0.704956321013; // D93
    else if (cwp == 1) cwp_norm = 0.816715709816; // D75
    else if (cwp == 2) cwp_norm = 0.923382193663; // D65
    // else if (cwp == 3) cwp_norm = 1.0f; // D60
    else if (cwp == 4) cwp_norm = 0.956138500287; // D55
    else if (cwp == 5) cwp_norm = 0.906801453023; // D50
  }
  /* Display Gamut - P3-DCI
    p3dci d93: 0.665336141225f
    p3dci d75: 0.770397131382f
    p3dci d65: 0.870572343302f
    p3dci d60: 0.891354547503f
    p3dci d55: 0.855327825187f
    p3dci d50: 0.814566436117f
*/
  else if (display_gamut == 4) { // P3DCI
    if (cwp == 0) cwp_norm = 0.665336141225; // D93
    else if (cwp == 1) cwp_norm = 0.770397131382; // D75
    else if (cwp == 2) cwp_norm = 0.870572343302; // D65
    else if (cwp == 3) cwp_norm = 0.891354547503; // D60
    else if (cwp == 4) cwp_norm = 0.855327825187; // D55
    else if (cwp == 5) cwp_norm = 0.814566436117; // D50
  }
  /* Display Gamut - DCDM XYZ
    p3dci d93: 0.707142784007f
    p3dci d75: 0.815561082617f
    */
  else if (display_gamut == 5) { // DCDM X'Y'Z'
    if (cwp == 0) cwp_norm =0.707142784007; // D93
    else if (cwp == 1) cwp_norm = 0.815561082617; // D75
    else if (cwp >= 2) cwp_norm = 0.916555279740; // 48/52.37 for D65 and warmer (see DCI spec)
  }
  
  // only normalize values affected by range control
  //rgb *= cwp_norm*cwp_f + 1.0f - cwp_f;
  rgb = mul_f3f(rgb, cwp_norm*cwp_f + 1.0 - cwp_f);
  
  return rgb;
}


float3 transform(float p_R, float p_G, float p_B,
                 int in_gamut,

                 int tn_hcon_enable,
                 int tn_lcon_enable,
                 int pt_enable,
                 int ptl_enable,
                 int ptm_enable,
                 int brl_enable,
                 int brlp_enable,
                 int hc_enable,
                 int hs_rgb_enable,
                 int hs_cmy_enable,
                 int cwp,
                 int tn_su,
                 int clamp,
                 int display_gamut,
                 int eotf,

                 float tn_con,
                 float tn_sh,
                 float tn_toe,
                 float tn_off,
                 float tn_hcon,
                 float tn_hcon_pv,
                 float tn_hcon_st,
                 float tn_lcon,
                 float tn_lcon_w,
                 float cwp_lm,
                 float rs_sa,
                 float rs_rw,
                 float rs_bw,
                 float pt_lml,
                 float pt_lml_r,
                 float pt_lml_g,
                 float pt_lml_b,
                 float pt_lmh,
                 float pt_lmh_r,
                 float pt_lmh_b,
                 float ptl_c,
                 float ptl_m,
                 float ptl_y,
                 float ptm_low,
                 float ptm_low_rng,
                 float ptm_low_st,
                 float ptm_high,
                 float ptm_high_rng,
                 float ptm_high_st,
                 float brl,
                 float brl_r,
                 float brl_g,
                 float brl_b,
                 float brl_rng,
                 float brl_st,
                 float brlp,
                 float brlp_r,
                 float brlp_g,
                 float brlp_b,
                 float hc_r,
                 float hc_r_rng,
                 float hs_r,
                 float hs_r_rng,
                 float hs_g,
                 float hs_g_rng,
                 float hs_b,
                 float hs_b_rng,
                 float hs_c,
                 float hs_c_rng,
                 float hs_m,
                 float hs_m_rng,
                 float hs_y,
                 float hs_y_rng,

                 float tn_Lp,
                 float tn_gb,
                 float pt_hdr,
                 float tn_Lg)
{
  float3 rgb = make_float3(p_R, p_G, p_B);

  float3x3 in_to_xyz;
  if (in_gamut==0) in_to_xyz = identity();
  else if (in_gamut==1) in_to_xyz = matrix_ap0_to_xyz;
  else if (in_gamut==2) in_to_xyz = matrix_ap1_to_xyz;
  else if (in_gamut==3) in_to_xyz = matrix_p3d65_to_xyz;
  else if (in_gamut==4) in_to_xyz = matrix_rec2020_to_xyz;
  else if (in_gamut==5) in_to_xyz = matrix_rec709_to_xyz;
  else if (in_gamut==6) in_to_xyz = matrix_arriwg3_to_xyz;
  else if (in_gamut==7) in_to_xyz = matrix_arriwg4_to_xyz;
  else if (in_gamut==8) in_to_xyz = matrix_redwg_to_xyz;
  else if (in_gamut==9) in_to_xyz = matrix_sonysgamut3_to_xyz;
  else if (in_gamut==10) in_to_xyz = matrix_sonysgamut3cine_to_xyz;
  else if (in_gamut==11) in_to_xyz = matrix_vgamut_to_xyz;
  else if (in_gamut==12) in_to_xyz = matrix_bmdwg_to_xyz;
  else if (in_gamut==13) in_to_xyz = matrix_egamut_to_xyz;
  else if (in_gamut==14) in_to_xyz = matrix_egamut2_to_xyz;
  else if (in_gamut==15) in_to_xyz = matrix_davinciwg_to_xyz;

  float crv_tsn = 0.0;

  /* // Linearize if a non-linear input oetf / transfer function is selected */
  /* rgb = linearize(rgb, in_oetf); */


  /***************************************************
    Tonescale Constraint Calculations
    https://www.desmos.com/calculator/1c4fhzy3bw

    These should be pre-calculated but there is no way to do this in DCTL.
    Anything that is const should be precalculated and not run per-pixel
    --------------------------------------------------*/
  const float ts_x1 = pow(2.0, 6.0*tn_sh + 4.0);
  const float ts_y1 = tn_Lp/100.0;
  const float ts_x0 = 0.18 + tn_off;
  const float ts_y0 = tn_Lg/100.0*(1.0 + tn_gb*log2(ts_y1));
  const float ts_s0 = compress_toe_quadratic(ts_y0, tn_toe, 1);
  const float ts_p = tn_con/(1.0 + tn_su*0.05); // unconstrained surround compensation
  const float ts_s10 = ts_x0*(pow(ts_s0, -1.0/tn_con) - 1.0);
  const float ts_m1 = ts_y1/pow(ts_x1/(ts_x1 + ts_s10), tn_con);
  const float ts_m2 = compress_toe_quadratic(ts_m1, tn_toe, 1);
  const float ts_s = ts_x0*(pow(ts_s0/ts_m2, -1.0/tn_con) - 1.0);
  const float ts_dsc = ite(eotf==4, 0.01, ite(eotf==5, 0.1, 100.0/tn_Lp));

  // Lerp from pt_cmp at 100 nits to pt_cmp_hdr at 1000 nits
  const float pt_cmp_Lf = pt_hdr*fmin(1.0, (tn_Lp - 100.0)/900.0);
  // Approximate scene-linear scale at Lp=100 nits
  const float s_Lp100 = ts_x0*(pow((tn_Lg/100.0), -1.0/tn_con) - 1.0);
  const float ts_s1 = ts_s*pt_cmp_Lf + s_Lp100*(1.0 - pt_cmp_Lf);


  // Convert from input gamut into P3-D65
  rgb = vdot(in_to_xyz, rgb);
  rgb = vdot(matrix_xyz_to_p3d65, rgb);


  // Rendering Space: "Desaturate" to control scale of the color volume in the rgb ratios.
  // Controlled by rs_sa (saturation) and red and blue weights (rs_rw and rs_bw)
  float3 rs_w = make_float3(rs_rw, 1.0 - rs_rw - rs_bw, rs_bw);
  float sat_L = rgb.x*rs_w.x + rgb.y*rs_w.y + rgb.z*rs_w.z;
  //rgb = sat_L*rs_sa + rgb*(1.0 - rs_sa);
  rgb = add_f3f(mul_f3f(rgb, 1.0-rs_sa), sat_L*rs_sa);


  // Offset
  /* rgb += tn_off; */
  rgb = add_f3f(rgb, tn_off);
  /* if (crv_enable == 1) crv_tsn += tn_off; */


  // Tonescale Norm
  float tsn = hypotf3(rgb)/SQRT3;

  // RGB Ratios
  rgb = sdivf3(rgb, tsn);
  
  float2 opp = opponent(rgb);
  float ach_d = hypotf2(opp)/2.0;
  
  // Smooth ach_d, normalized so 1.0 doesn't change https://www.desmos.com/calculator/ozjg09hzef
  ach_d = (1.25)*compress_toe_quadratic(ach_d, 0.25, 0);

  // Hue angle, rotated so that red = 0.0
  float hue = fmod(atan2(opp.x, opp.y) + PI + 1.10714931, 2.0*PI);

  // RGB Hue Angles
  // Wider than CMY by default. R towards M, G towards Y, B towards C
  float3 ha_rgb = make_float3(
    gauss_window(hue_offset(hue, 0.1), 0.66),
    gauss_window(hue_offset(hue, 4.3), 0.66),
    gauss_window(hue_offset(hue, 2.3), 0.66));
    
  // RGB Hue Angles for hue shift: red shifted more orange
  float3 ha_rgb_hs = make_float3(
    gauss_window(hue_offset(hue, -0.4), 0.66),
    ha_rgb.y,
    gauss_window(hue_offset(hue, 2.5), 0.66));
  
  // CMY Hue Angles
  // Exact alignment to Cyan/Magenta/Yellow secondaries would be PI, PI/3 and -PI/3, but
  // we customize these a bit for creative purposes: M towards B, Y towards G, C towards G
  float3 ha_cmy = make_float3(
    gauss_window(hue_offset(hue, 3.3), 0.5),
    gauss_window(hue_offset(hue, 1.3), 0.5),
    gauss_window(hue_offset(hue, -1.15), 0.5));


  // Brilliance
  if (brl_enable) {
    float brl_tsf = pow(tsn/(tsn + 1.0), 1.0 - brl_rng);
    float brl_exf = (brl + brl_r*ha_rgb.x + brl_g*ha_rgb.y + brl_b*ha_rgb.z)*pow(ach_d, 1.0/brl_st);
    float brl_ex = pow(2.0, brl_exf*(ite(brl_exf < 0.0, brl_tsf, 1.0 - brl_tsf)));
    tsn = tsn * brl_ex;
  }

  // Contrast Low 
  if (tn_lcon_enable) {
    float lcon_m = pow(2.0, -tn_lcon);
    float lcon_w = tn_lcon_w/4.0;
    lcon_w = lcon_w * lcon_w;
    
    // Normalize for ts_x0 intersection constraint: https://www.desmos.com/calculator/blyvi8t2b2
    const float lcon_cnst_sc = compress_toe_cubic(ts_x0, lcon_m, lcon_w, 1)/ts_x0;
    tsn = tsn * lcon_cnst_sc;
    tsn = compress_toe_cubic(tsn, lcon_m, lcon_w, 0);
    
    //if (crv_enable == 1) crv_tsn = compress_toe_cubic(crv_tsn*lcon_cnst_sc, lcon_m, lcon_w, 0);
  }

  // Contrast High
  if (tn_hcon_enable) {
    float hcon_p = pow(2.0, tn_hcon);
    tsn = contrast_high(tsn, hcon_p, tn_hcon_pv, tn_hcon_st, 0);
    
    //if (crv_enable == 1) crv_tsn = contrast_high(crv_tsn, hcon_p, tn_hcon_pv, tn_hcon_st, 0);
  }

  // Hyperbolic Compression
  float tsn_pt = compress_hyperbolic_power(tsn, ts_s1, ts_p);
  float tsn_const = compress_hyperbolic_power(tsn, s_Lp100, ts_p);
  tsn = compress_hyperbolic_power(tsn, ts_s, ts_p);
  
  float crv_tsn_const = 0.0;
  /* if (crv_enable == 1) { */
  /*   crv_tsn_const = compress_hyperbolic_power(crv_tsn, s_Lp100, ts_p); */
  /*   crv_tsn = compress_hyperbolic_power(crv_tsn, ts_s, ts_p); */
  /* } */



  /***************************************************
    Hue Contrast R
  --------------------------------------------------*/
  if (hc_enable) {
    float hc_ts = 1.0 - tsn_const;
    // Limit high purity on bottom end and low purity on top end by ach_d.
    // This helps reduce artifacts and over-saturation.
    float hc_c = hc_ts*(1.0 - ach_d) + ach_d*(1.0 - hc_ts);
    hc_c = hc_c * ach_d*ha_rgb.x;
    hc_ts = pow(hc_ts, 1.0/hc_r_rng);
    // Bias contrast based on tonescale using Lift/Mult: https://www.desmos.com/calculator/gzbgov62hl
    float hc_f = hc_r*(hc_c - 2.0*hc_c*hc_ts) + 1.0;
    rgb = make_float3(rgb.x, rgb.y*hc_f, rgb.z*hc_f);
  }



  /***************************************************
    Hue Shift
  --------------------------------------------------*/
  // Hue Shift RGB by purity compress tonescale, shifting more as intensity increases
  if (hs_rgb_enable) {
    float3 hs_rgb = make_float3(
      ha_rgb_hs.x*ach_d*pow(tsn_pt, 1.0/hs_r_rng),
      ha_rgb_hs.y*ach_d*pow(tsn_pt, 1.0/hs_g_rng),
      ha_rgb_hs.z*ach_d*pow(tsn_pt, 1.0/hs_b_rng));
    float3 hsf = make_float3(hs_rgb.x*hs_r, hs_rgb.y*-hs_g, hs_rgb.z*-hs_b);
    hsf = make_float3(hsf.z - hsf.y, hsf.x - hsf.z, hsf.y - hsf.x);
    //rgb += hsf;
    rgb = add_f3f3(rgb, hsf);
  }

  // Hue Shift CMY by tonescale, shifting less as intensity increases
  if (hs_cmy_enable) {
    float tsn_pt_compl = 1.0 - tsn_pt;
    float3 hs_cmy = make_float3(
      ha_cmy.x*ach_d*pow(tsn_pt_compl, 1.0/hs_c_rng),
      ha_cmy.y*ach_d*pow(tsn_pt_compl, 1.0/hs_m_rng),
      ha_cmy.z*ach_d*pow(tsn_pt_compl, 1.0/hs_y_rng));
    float3 hsf = make_float3(hs_cmy.x*-hs_c, hs_cmy.y*hs_m, hs_cmy.z*hs_y);
    hsf = make_float3(hsf.z - hsf.y, hsf.x - hsf.z, hsf.y - hsf.x);
    //rgb += hsf;
    rgb = add_f3f3(rgb, hsf);
  }



  /***************************************************
    Purity Compression
      https://www.desmos.com/calculator/adtzkjofgn
  --------------------------------------------------*/
  // Purity Limit Low
  float pt_lml_p = 1.0 + 4.0*(1.0 - tsn_pt)*(pt_lml + pt_lml_r*ha_rgb_hs.x + pt_lml_g*ha_rgb_hs.y + pt_lml_b*ha_rgb_hs.z);
  float ptf = 1.0 - pow(tsn_pt, pt_lml_p);
  
  // Purity Limit High
  float pt_lmh_p = (1.0 - ach_d*(pt_lmh_r*ha_rgb_hs.x + pt_lmh_b*ha_rgb_hs.z))*(1.0 - pt_lmh*ach_d);
  ptf = pow(ptf, pt_lmh_p);

  
  /***************************************************
    Mid-Range Purity
      This boosts mid-range purity on the low end
      and reduces mid-range purity on the high end
  --------------------------------------------------*/
  if (ptm_enable) {
    float ptm_low_f;
    if (ptm_low_st == 0.0 || ptm_low_rng == 0.0) ptm_low_f = 1.0;
    else ptm_low_f = 1.0 + ptm_low*exp(-2.0*ach_d*ach_d/ptm_low_st)*pow(1.0 - tsn_const, 1.0/ptm_low_rng);
    float ptm_high_f;
    if (ptm_high_st == 0.0 || ptm_high_rng == 0.0) ptm_high_f = 1.0;
    else ptm_high_f = 1.0 + ptm_high*exp(-2.0*ach_d*ach_d/ptm_high_st)*pow(tsn_pt, 1.0/(4.0*ptm_high_rng));
    ptf = ptf * ptm_low_f*ptm_high_f;
  }

  // Lerp to peak achromatic by ptf in rgb ratios
  //rgb = rgb*ptf + 1.0 - ptf;
  rgb = add_f3f(mul_f3f(rgb, ptf), 1.0-ptf);

  // Inverse Rendering Space
  sat_L = rgb.x*rs_w.x + rgb.y*rs_w.y + rgb.z*rs_w.z;
  //rgb = (sat_L*rs_sa - rgb)/(rs_sa - 1.0);
  rgb = add_f3f(mul_f3f(rgb, -1.0/(rs_sa - 1.0)), (sat_L*rs_sa)/(rs_sa - 1.0));

  // Convert to final display gamut and set whitepoint
  rgb = display_gamut_whitepoint(rgb, tsn_const, cwp_lm, display_gamut, cwp);
  
  // Post Brilliance
  if (brlp_enable) {
    float2 brlp_opp = opponent(rgb);
    float brlp_ach_d = hypotf2(brlp_opp)/4.0;
    // brlp_ach_d = 1.0 - gauss_window(brlp_ach_d, 8.0);
    brlp_ach_d = 1.1*(brlp_ach_d*brlp_ach_d/(brlp_ach_d + 0.1));
    //float3 brlp_ha_rgb = ach_d*ha_rgb;
    float3 brlp_ha_rgb = mul_f3f(ha_rgb, ach_d);
    float brlp_m = brlp + brlp_r*brlp_ha_rgb.x + brlp_g*brlp_ha_rgb.y + brlp_b*brlp_ha_rgb.z;
    float brlp_ex = pow(2.0, brlp_m*brlp_ach_d*tsn);
    //rgb *= brlp_ex;
    rgb = mul_f3f(rgb, brlp_ex);
  }

  // Purity Compress Low
  if (ptl_enable) rgb = make_float3(softplus(rgb.x, ptl_c), softplus(rgb.y, ptl_m), softplus(rgb.z, ptl_y));
 
  // Final tonescale adjustments
  tsn = tsn * ts_m2; // scale for inverse toe
  tsn = compress_toe_quadratic(tsn, tn_toe, 0);
  tsn = tsn * ts_dsc; // scale for display encoding
  
  /* if (crv_enable == 1) { */
  /*   crv_tsn *= ts_m2; */
  /*   crv_tsn = compress_toe_quadratic(crv_tsn, tn_toe, 0); */
  /*   crv_tsn *= ts_dsc; */
  /*   // scale to 1.0 = 1000 nits for st2084 PQ */
  /*   if (eotf == 4) crv_tsn *= 10.0; */
  /* } */

  /* float3 crv_rgb = make_float3(crv_tsn, crv_tsn, crv_tsn); */
  /* if (crv_enable == 1) crv_rgb = display_gamut_whitepoint(crv_rgb, crv_tsn_const, cwp_lm, display_gamut, cwp); */

  // Return from RGB ratios
  //rgb *= tsn;
  rgb = mul_f3f(rgb, tsn);

  // Rec.2020 (P3 Limited)
  if (display_gamut==2) {
    rgb = clampminf3(rgb, 0.0); // Limit to P3 gamut
    rgb = vdot(matrix_p3_to_rec2020, rgb);
  }
  
  // Clamp
  if (clamp) rgb = clampf3(rgb, 0.0, 1.0);

  // Apply inverse Display EOTF
  /* float eotf_p = 2.0 + eotf * 0.2; */
  /* if ((eotf > 0) && (eotf < 4)) rgb = spowf3(rgb, 1.0/eotf_p); */
  /* else if (eotf == 4) rgb = eotf_pq(rgb, 1); */
  /* else if (eotf == 5) rgb = eotf_hlg(rgb, 1); */
  
  /* if (crv_enable == 1) { */
  /*   if ((eotf > 0) && (eotf < 4)) crv_rgb = spowf3(crv_rgb, 1.0/eotf_p); */
  /*   else if (eotf == 4) crv_rgb = eotf_pq(crv_rgb, 1); */
  /*   else if (eotf == 5) crv_rgb = eotf_hlg(crv_rgb, 1); */
  /* } */
  
  
  /* // Draw tonescale overlay */
  /* if (crv_enable == 1) { */
  /*   float3 crv_rgb_dst = make_float3(res.y-pos.y-crv_rgb.x*res.y, res.y-pos.y-crv_rgb.y*res.y, res.y-pos.y-crv_rgb.z*res.y); */
  /*   float crv_w0 = 0.35; // width of tonescale overlay */
  /*   crv_rgb_dst.x = exp(-crv_rgb_dst.x*crv_rgb_dst.x*crv_w0); */
  /*   crv_rgb_dst.y = exp(-crv_rgb_dst.y*crv_rgb_dst.y*crv_w0); */
  /*   crv_rgb_dst.z = exp(-crv_rgb_dst.z*crv_rgb_dst.z*crv_w0); */
  /*   float crv_lm = ite(eotf < 4, 1.0, 1.0); // reduced luminance in hdr */
  /*   crv_rgb_dst = clampf3(crv_rgb_dst, 0.0, 1.0); */
  /*   rgb = rgb * (1.0 - crv_rgb_dst) + make_float3(crv_lm, crv_lm, crv_lm)*crv_rgb_dst; */
  /* } */
  
  return rgb;
}

//-----------------------------------------------------------------------------

// @ART-label: "$CTL_ODRT_OPENDRT_FULL;OpenDRT Full"
// @ART-colorspace: "rec2020"
// @ART-lut: 64

// @ART-param: ["ex", "$CTL_ODRT_GAIN;Exposure", -4.0, 4.0, 0.697437, 0.01]
// @ART-param: ["tn_Lp", "$CTL_ODRT_DISPLAY_PEAK_LUMINANCE;Display Peak Luminance", 100, 1000, 100, 0.1]
// @ART-param: ["tn_gb", "$CTL_ODRT_HDR_GREY_BOOST;HDR Grey Boost", 0, 1, 0.13, 0.01]
// @ART-param: ["pt_hdr", "$CTL_ODRT_HDR_PURITY;HDR Purity", 0, 1, 0.5, 0.01]
// @ART-param: ["tn_Lg", "$CTL_ODRT_DISPLAY_GREY_LUMINANCE;Display Grey Luminance", 2, 25, 10, 0.1]
// @ART-param: ["tn_con", "$CTL_CONTRAST;Contrast", 1.0, 2.0, 1.66, 0.01]
// @ART-param: ["tn_sh", "$CTL_ODRT_SHOULDER_CLIP;Shoulder Clip", 0.0, 1.0, 0.5, 0.01]
// @ART-param: ["tn_toe", "$CTL_ODRT_TOE;Toe", 0.0, 0.1, 0.003, 0.001]
// @ART-param: ["tn_off", "$CTL_OFFSET;Offset", 0.0, 0.02, 0.005, 0.0001]
// @ART-param: ["tn_hcon_enable", "$CTL_ODRT_ENABLE;Enable", false, "$CTL_ODRT_CONTRAST_HIGH;Contrast High"]
// @ART-param: ["tn_hcon", "$CTL_ODRT_VALUE;Value", -1.0, 1.0, 0.0, 0.01, "$CTL_ODRT_CONTRAST_HIGH;Contrast High"]
// @ART-param: ["tn_hcon_pv", "$CTL_ODRT_PIVOT;Pivot", 0.0, 4.0, 1.0, 0.01, "$CTL_ODRT_CONTRAST_HIGH;Contrast High"]
// @ART-param: ["tn_hcon_st", "$CTL_ODRT_STRENGTH;Strength", 0.0, 4.0, 4.0, 0.01, "$CTL_ODRT_CONTRAST_HIGH;Contrast High"]
// @ART-param: ["tn_lcon_enable", "$CTL_ODRT_ENABLE;Enable", false, "$CTL_ODRT_CONTRAST_LOW;Contrast Low"]
// @ART-param: ["tn_lcon", "$CTL_ODRT_VALUE;Value", 0.0, 3.0, 0.0, 0.01, "$CTL_ODRT_CONTRAST_LOW;Contrast Low"]
// @ART-param: ["tn_lcon_w", "$CTL_ODRT_WIDTH;Width", 0.0, 2.0, 0.5, 0.01, "$CTL_ODRT_CONTRAST_LOW;Contrast Low"]
// @ART-param: ["cwp", "$CTL_ODRT_TEMPERATURE;Temperature", ["D93", "D75", "D65", "D60", "D55", "D50"], 2, "$CTL_ODRT_CREATIVE_WHITE;Creative White"]
// @ART-param: ["cwp_lm", "$CTL_LIMIT;Limit", 0.0, 1.0, 0.25, 0.01, "$CTL_ODRT_CREATIVE_WHITE;Creative White"]
// @ART-param: ["rs_sa", "$CTL_STRENGTH;Strength", 0.0, 0.6, 0.35, 0.001, "$CTL_ODRT_RENDER_SPACE;Render Space"]
// @ART-param: ["rs_rw", "$CTL_ODRT_WEIGHT_R;Weight R", 0.0, 0.8, 0.25, 0.001, "$CTL_ODRT_RENDER_SPACE;Render Space"]
// @ART-param: ["rs_bw", "$CTL_ODRT_WEIGHT_B;Weight B", 0.0, 0.8, 0.55, 0.001, "$CTL_ODRT_RENDER_SPACE;Render Space"]
// @ART-param: ["pt_enable", "$CTL_ODRT_ENABLE;Enable", true, "$CTL_ODRT_PURITY_COMPRESS;Purity Compress"]
// @ART-param: ["pt_lml", "$CTL_ODRT_LIMIT_LOW;Limit Low", 0.0, 1.0, 0.25, 0.01, "$CTL_ODRT_PURITY_COMPRESS;Purity Compress"]
// @ART-param: ["pt_lml_r", "$CTL_ODRT_LIMIT_LOW_R;Limit Low R", 0.0, 1.0, 0.5, 0.01, "$CTL_ODRT_PURITY_COMPRESS;Purity Compress"]
// @ART-param: ["pt_lml_g", "$CTL_ODRT_LIMIT_LOW_G;Limit Low G", 0.0, 1.0, 0.0, 0.01, "$CTL_ODRT_PURITY_COMPRESS;Purity Compress"]
// @ART-param: ["pt_lml_b", "$CTL_ODRT_LIMIT_LOW_B;Limit Low B", 0.0, 1.0, 0.1, 0.01, "$CTL_ODRT_PURITY_COMPRESS;Purity Compress"]
// @ART-param: ["pt_lmh", "$CTL_ODRT_LIMIT_HIGHT;Limit High", 0.0, 1.0, 0.25, 0.01, "$CTL_ODRT_PURITY_COMPRESS;Purity Compress"]
// @ART-param: ["pt_lmh_r", "$CTL_ODRT_LIMIT_HIGHT_R;Limit High R", 0.0, 1.0, 0.5, 0.01, "$CTL_ODRT_PURITY_COMPRESS;Purity Compress"]
// @ART-param: ["pt_lmh_b", "$CTL_ODRT_LIMIT_HIGHT_B;Limit High B", 0.0, 1.0, 0.0, 0.01, "$CTL_ODRT_PURITY_COMPRESS;Purity Compress"]
// @ART-param: ["ptl_enable", "$CTL_ODRT_ENABLE;Enable", true, "$CTL_ODRT_PURITY_SOFTCLIP;Purity Softclip"]
// @ART-param: ["ptl_c", "C", 0.0, 0.25, 0.06, 0.001, "$CTL_ODRT_PURITY_SOFTCLIP;Purity Softclip"]
// @ART-param: ["ptl_m", "M", 0.0, 0.25, 0.08, 0.001, "$CTL_ODRT_PURITY_SOFTCLIP;Purity Softclip"]
// @ART-param: ["ptl_y", "Y", 0.0, 0.25, 0.06, 0.001, "$CTL_ODRT_PURITY_SOFTCLIP;Purity Softclip"]
// @ART-param: ["ptm_enable", "$CTL_ODRT_ENABLE;Enable", true, "$CTL_ODRT_MID_PURITY;Mid Purity"]
// @ART-param: ["ptm_low", "$CTL_ODRT_LOW;Low", 0.0, 2.0, 0.5, 0.02, "$CTL_ODRT_MID_PURITY;Mid Purity"]
// @ART-param: ["ptm_low_rng", "$CTL_ODRT_LOW_RANGE;Low Range", 0.0, 1.0, 0.25, 0.01, "$CTL_ODRT_MID_PURITY;Mid Purity"]
// @ART-param: ["ptm_low_st", "$CTL_ODRT_LOW_STRENGTH;Low Strength", 0.1, 1.0, 0.5, 0.01, "$CTL_ODRT_MID_PURITY;Mid Purity"]
// @ART-param: ["ptm_high", "$CTL_ODRT_HIGH;High", -0.9, 0.0, -0.8, 0.01, "$CTL_ODRT_MID_PURITY;Mid Purity"]
// @ART-param: ["ptm_high_rng", "$CTL_ODRT_HIGH_RANGE;High Range", 0.0, 1.0, 0.3, 0.01, "$CTL_ODRT_MID_PURITY;Mid Purity"]
// @ART-param: ["ptm_high_st", "$CTL_ODRT_HIGH_STRENGTH;High Strength", 0.1, 1.0, 0.4, 0.01, "$CTL_ODRT_MID_PURITY;Mid Purity"]
// @ART-param: ["brl_enable", "$CTL_ODRT_ENABLE;Enable", true, "$CTL_ODRT_BRILLANCE;Brilliance"]
// @ART-param: ["brl", "$CTL_ODRT_VALUE;Value", -6.0, 2.0, 0.0, 0.01, "$CTL_ODRT_BRILLANCE;Brilliance"]
// @ART-param: ["brl_r", "R", -6.0, 2.0, -2.5, 0.01, "$CTL_ODRT_BRILLANCE;Brilliance"]
// @ART-param: ["brl_g", "G", -6.0, 2.0, -1.5, 0.01, "$CTL_ODRT_BRILLANCE;Brilliance"]
// @ART-param: ["brl_b", "B", -6.0, 2.0, -1.5, 0.01, "$CTL_ODRT_BRILLANCE;Brilliance"]
// @ART-param: ["brl_rng", "$CTL_ODRT_RANGE;Range", 0.0, 1.0, 0.5, 0.01, "$CTL_ODRT_BRILLANCE;Brilliance"]
// @ART-param: ["brl_st", "$CTL_STRENGTH;Strength", 0.0, 1.0, 0.35, 0.01, "$CTL_ODRT_BRILLANCE;Brilliance"]
// @ART-param: ["brlp_enable", "$CTL_ODRT_ENABLE;Enable", true, "$CTL_ODRT_POST_BRILLANCE;Post Brilliance"]
// @ART-param: ["brlp", "$CTL_ODRT_VALUE;Value", -1.0, 0.0, -0.5, 0.01, "$CTL_ODRT_POST_BRILLANCE;Post Brilliance"]
// @ART-param: ["brlp_r", "R", -3.0, 0.0, -1.25, 0.01, "$CTL_ODRT_POST_BRILLANCE;Post Brilliance"]
// @ART-param: ["brlp_g", "G", -3.0, 0.0, -1.25, 0.01, "$CTL_ODRT_POST_BRILLANCE;Post Brilliance"]
// @ART-param: ["brlp_b", "B", -3.0, 0.0, -0.25, 0.01, "$CTL_ODRT_POST_BRILLANCE;Post Brilliance"]
// @ART-param: ["hc_enable", "$CTL_ODRT_ENABLE;Enable", true, "$CTL_ODRT_HUE_CONTRAST;Hue Contrast"]
// @ART-param: ["hc_r", "R", 0.0, 2.0, 1.0, 0.01, "$CTL_ODRT_HUE_CONTRAST;Hue Contrast"]
// @ART-param: ["hc_r_rng", "$CTL_ODRT_R_RANGE;R Range", 0.0, 1.0, 0.3, 0.01, "$CTL_ODRT_HUE_CONTRAST;Hue Contrast"]
// @ART-param: ["hs_rgb_enable", "$CTL_ODRT_ENABLE;Enable", true, "$CTL_ODRT_HUESHIFT_RGB;Hueshift RGB"]
// @ART-param: ["hs_r", "R", 0.0, 1.0, 0.6, 0.01, "$CTL_ODRT_HUESHIFT_RGB;Hueshift RGB"]
// @ART-param: ["hs_r_rng", "$CTL_ODRT_R_RANGE;R Range", 0.0, 2.0, 0.7, 0.01, "$CTL_ODRT_HUESHIFT_RGB;Hueshift RGB"]
// @ART-param: ["hs_g", "G", 0.0, 1.0, 0.35, 0.01, "$CTL_ODRT_HUESHIFT_RGB;Hueshift RGB"]
// @ART-param: ["hs_g_rng", "$CTL_ODRT_G_RANGE;G Range", 0.0, 2.0, 1.0, 0.01, "$CTL_ODRT_HUESHIFT_RGB;Hueshift RGB"]
// @ART-param: ["hs_b", "B", 0.0, 1.0, 0.66, 0.01, "$CTL_ODRT_HUESHIFT_RGB;Hueshift RGB"]
// @ART-param: ["hs_b_rng", "$CTL_ODRT_B_RANGE;B Range", 0.0, 2.0, 1.0, 0.01, "$CTL_ODRT_HUESHIFT_RGB;Hueshift RGB"]
// @ART-param: ["hs_cmy_enable", "$CTL_ODRT_ENABLE;Enable", true, "$CTL_ODRT_HUESHIFT_CMY;Hueshift CMY"]
// @ART-param: ["hs_c", "C", 0.0, 1.0, 0.25, 0.01, "$CTL_ODRT_HUESHIFT_CMY;Hueshift CMY"]
// @ART-param: ["hs_c_rng", "$CTL_ODRT_C_RANGE;C Range", 0.0, 1.0, 1.0, 0.01, "$CTL_ODRT_HUESHIFT_CMY;Hueshift CMY"]
// @ART-param: ["hs_m", "M", 0.0, 1.0, 0.0, 0.01, "$CTL_ODRT_HUESHIFT_CMY;Hueshift CMY"]
// @ART-param: ["hs_m_rng", "$CTL_ODRT_M_RANGE;M Range", 0.0, 1.0, 1.0, 0.01, "$CTL_ODRT_HUESHIFT_CMY;Hueshift CMY"]
// @ART-param: ["hs_y", "Y", 0.0, 1.0, 0.0, 0.01, "$CTL_ODRT_HUESHIFT_CMY;Hueshift CMY"]
// @ART-param: ["hs_y_rng", "$CTL_ODRT_Y_RANGE;Y Range", 0.0, 1.0, 1.0, 0.01, "$CTL_ODRT_HUESHIFT_CMY;Hueshift CMY"]

// @ART-param: ["tn_su", "$CTL_ODRT_SURROUND;Surround", ["$CTL_ODRT_DARK;Dark", "$CTL_ODRT_DIM;Dim", "$CTL_ODRT_BRIGHT;Bright"], 1]
// @ART-param: ["display_gamut", "$CTL_ODRT_DISPLAY_GAMUT;Display gamut", ["Rec.709", "P3 D65", "Rec.2020"]]

// @ART-preset: ["look_standard", "$CTL_ODRT_LOOK_STANDARD;Look - Standard", { "tn_con" : 1.66, "tn_sh" : 0.5, "tn_toe" : 0.003, "tn_off" : 0.005, "tn_hcon_enable" : false, "tn_hcon" : 0.0, "tn_hcon_pv" : 1.0, "tn_hcon_st" : 4.0, "tn_lcon_enable" : false, "tn_lcon" : 0.0, "tn_lcon_w" : 0.5, "cwp" : 2, "cwp_lm" : 0.25, "rs_sa" : 0.35, "rs_rw" : 0.25, "rs_bw" : 0.55, "pt_enable" : true, "pt_lml" : 0.25, "pt_lml_r" : 0.5, "pt_lml_g" : 0.0, "pt_lml_b" : 0.1, "pt_lmh" : 0.25, "pt_lmh_r" : 0.5, "pt_lmh_b" : 0.0, "ptl_enable" : true, "ptl_c" : 0.06, "ptl_m" : 0.08, "ptl_y" : 0.06, "ptm_enable" : true, "ptm_low" : 0.5, "ptm_low_rng" : 0.25, "ptm_low_st" : 0.5, "ptm_high" : -0.8, "ptm_high_rng" : 0.3, "ptm_high_st" : 0.4, "brl_enable" : true, "brl" : 0.0, "brl_r" : -2.5, "brl_g" : -1.5, "brl_b" : -1.5, "brl_rng" : 0.5, "brl_st" : 0.35, "brlp_enable" : true, "brlp" : -0.5, "brlp_r" : -1.25, "brlp_g" : -1.25, "brlp_b" : -0.25, "hc_enable" : true, "hc_r" : 1.0, "hc_r_rng" : 0.3, "hs_rgb_enable" : true, "hs_r" : 0.6, "hs_r_rng" : 0.7, "hs_g" : 0.35, "hs_g_rng" : 1.0, "hs_b" : 0.66, "hs_b_rng" : 1.0, "hs_cmy_enable" : true, "hs_c" : 0.25, "hs_c_rng" : 1.0, "hs_m" : 0.0, "hs_m_rng" : 1.0, "hs_y" : 0.0, "hs_y_rng" : 1.0 }]
// 
// @ART-preset: ["look_arriba", "$CTL_ODRT_LOOK_ARRIBA;Look - Arriba", { "tn_con" : 1.05, "tn_sh" : 0.5, "tn_toe" : 0.1, "tn_off" : 0.01, "tn_hcon_enable" : false, "tn_hcon" : 0.0, "tn_hcon_pv" : 1.0, "tn_hcon_st" : 4.0, "tn_lcon_enable" : true, "tn_lcon" : 1.5, "tn_lcon_w" : 0.2, "cwp" : 2, "cwp_lm" : 0.25, "rs_sa" : 0.35, "rs_rw" : 0.25, "rs_bw" : 0.55, "pt_enable" : true, "pt_lml" : 0.25, "pt_lml_r" : 0.45, "pt_lml_g" : 0.0, "pt_lml_b" : 0.1, "pt_lmh" : 0.25, "pt_lmh_r" : 0.25, "pt_lmh_b" : 0.0, "ptl_enable" : true, "ptl_c" : 0.06, "ptl_m" : 0.08, "ptl_y" : 0.06, "ptm_enable" : true, "ptm_low" : 1.0, "ptm_low_rng" : 0.4, "ptm_low_st" : 0.5, "ptm_high" : -0.8, "ptm_high_rng" : 0.66, "ptm_high_st" : 0.6, "brl_enable" : true, "brl" : 0.0, "brl_r" : -2.5, "brl_g" : -1.5, "brl_b" : -1.5, "brl_rng" : 0.5, "brl_st" : 0.35, "brlp_enable" : true, "brlp" : 0.0, "brlp_r" : -1.7, "brlp_g" : -2.0, "brlp_b" : -0.5, "hc_enable" : true, "hc_r" : 1.0, "hc_r_rng" : 0.3, "hs_rgb_enable" : true, "hs_r" : 0.6, "hs_r_rng" : 0.8, "hs_g" : 0.35, "hs_g_rng" : 1.0, "hs_b" : 0.66, "hs_b_rng" : 1.0, "hs_cmy_enable" : true, "hs_c" : 0.15, "hs_c_rng" : 1.0, "hs_m" : 0.0, "hs_m_rng" : 1.0, "hs_y" : 0.0, "hs_y_rng" : 1.0 } ]
// 
// @ART-preset: ["look_sylvan", "$CTL_ODRT_LOOK_SYLVAN;Look - Sylvan", { "tn_con" : 1.6, "tn_sh" : 0.5, "tn_toe" : 0.01, "tn_off" : 0.01, "tn_hcon_enable" : false, "tn_hcon" : 0.0, "tn_hcon_pv" : 1.0, "tn_hcon_st" : 4.0, "tn_lcon_enable" : true, "tn_lcon" : 0.25, "tn_lcon_w" : 0.75, "cwp" : 2, "cwp_lm" : 0.25, "rs_sa" : 0.25, "rs_rw" : 0.25, "rs_bw" : 0.55, "pt_enable" : true, "pt_lml" : 0.15, "pt_lml_r" : 0.5, "pt_lml_g" : 0.15, "pt_lml_b" : 0.1, "pt_lmh" : 0.25, "pt_lmh_r" : 0.15, "pt_lmh_b" : 0.15, "ptl_enable" : true, "ptl_c" : 0.05, "ptl_m" : 0.08, "ptl_y" : 0.05, "ptm_enable" : true, "ptm_low" : 0.5, "ptm_low_rng" : 0.5, "ptm_low_st" : 0.5, "ptm_high" : -0.8, "ptm_high_rng" : 0.5, "ptm_high_st" : 0.5, "brl_enable" : true, "brl" : -1.0, "brl_r" : -2.0, "brl_g" : -2.0, "brl_b" : 0.0, "brl_rng" : 0.25, "brl_st" : 0.25, "brlp_enable" : true, "brlp" : -1.0, "brlp_r" : -0.5, "brlp_g" : -0.25, "brlp_b" : -0.25, "hc_enable" : true, "hc_r" : 1.0, "hc_r_rng" : 0.4, "hs_rgb_enable" : true, "hs_r" : 0.6, "hs_r_rng" : 1.15, "hs_g" : 0.8, "hs_g_rng" : 1.25, "hs_b" : 0.6, "hs_b_rng" : 1.0, "hs_cmy_enable" : true, "hs_c" : 0.25, "hs_c_rng" : 0.25, "hs_m" : 0.25, "hs_m_rng" : 0.5, "hs_y" : 0.35, "hs_y_rng" : 0.5 }]
// 
// @ART-preset: ["look_colorful", "$CTL_ODRT_LOOK_COLORFUL;Look - Colorful", { "tn_con" : 1.5, "tn_sh" : 0.5, "tn_toe" : 0.003, "tn_off" : 0.003, "tn_hcon_enable" : false, "tn_hcon" : 0.0, "tn_hcon_pv" : 1.0, "tn_hcon_st" : 4.0, "tn_lcon_enable" : true, "tn_lcon" : 0.4, "tn_lcon_w" : 0.5, "cwp" : 2, "cwp_lm" : 0.25, "rs_sa" : 0.35, "rs_rw" : 0.25, "rs_bw" : 0.55, "pt_enable" : true, "pt_lml" : 0.5, "pt_lml_r" : 1.0, "pt_lml_g" : 0.0, "pt_lml_b" : 0.5, "pt_lmh" : 0.25, "pt_lmh_r" : 0.25, "pt_lmh_b" : 0.15, "ptl_enable" : true, "ptl_c" : 0.05, "ptl_m" : 0.06, "ptl_y" : 0.05, "ptm_enable" : true, "ptm_low" : 0.8, "ptm_low_rng" : 0.5, "ptm_low_st" : 0.4, "ptm_high" : -0.8, "ptm_high_rng" : 0.3, "ptm_high_st" : 0.4, "brl_enable" : true, "brl" : 0.0, "brl_r" : -1.25, "brl_g" : -1.25, "brl_b" : -0.25, "brl_rng" : 0.3, "brl_st" : 0.5, "brlp_enable" : true, "brlp" : -0.5, "brlp_r" : -1.25, "brlp_g" : -1.25, "brlp_b" : 0.0, "hc_enable" : true, "hc_r" : 1.0, "hc_r_rng" : 0.4, "hs_rgb_enable" : true, "hs_r" : 0.5, "hs_r_rng" : 0.8, "hs_g" : 0.35, "hs_g_rng" : 1.0, "hs_b" : 0.5, "hs_b_rng" : 1.0, "hs_cmy_enable" : true, "hs_c" : 0.25, "hs_c_rng" : 1.0, "hs_m" : 0.0, "hs_m_rng" : 1.0, "hs_y" : 0.25, "hs_y_rng" : 1.0 }]
// 
// @ART-preset: ["look_aery", "$CTL_ODRT_LOOK_AERY;Look - Aery", { "tn_con" : 1.15, "tn_sh" : 0.5, "tn_toe" : 0.04, "tn_off" : 0.006, "tn_hcon_enable" : false, "tn_hcon" : 0.0, "tn_hcon_pv" : 0.0, "tn_hcon_st" : 0.5, "tn_lcon_enable" : true, "tn_lcon" : 0.5, "tn_lcon_w" : 2.0, "cwp" : 1, "cwp_lm" : 0.25, "rs_sa" : 0.25, "rs_rw" : 0.2, "rs_bw" : 0.5, "pt_enable" : true, "pt_lml" : 0.0, "pt_lml_r" : 0.35, "pt_lml_g" : 0.15, "pt_lml_b" : 0.1, "pt_lmh" : 0.0, "pt_lmh_r" : 0.5, "pt_lmh_b" : 0.0, "ptl_enable" : true, "ptl_c" : 0.05, "ptl_m" : 0.08, "ptl_y" : 0.05, "ptm_enable" : true, "ptm_low" : 0.8, "ptm_low_rng" : 0.35, "ptm_low_st" : 0.5, "ptm_high" : -0.9, "ptm_high_rng" : 0.5, "ptm_high_st" : 0.3, "brl_enable" : true, "brl" : -3.0, "brl_r" : 0.0, "brl_g" : 0.0, "brl_b" : 1.0, "brl_rng" : 0.8, "brl_st" : 0.15, "brlp_enable" : true, "brlp" : -1.0, "brlp_r" : -1.0, "brlp_g" : -1.0, "brlp_b" : 0.0, "hc_enable" : true, "hc_r" : 0.5, "hc_r_rng" : 0.25, "hs_rgb_enable" : true, "hs_r" : 0.6, "hs_r_rng" : 1.0, "hs_g" : 0.35, "hs_g_rng" : 2.0, "hs_b" : 0.5, "hs_b_rng" : 1.5, "hs_cmy_enable" : true, "hs_c" : 0.35, "hs_c_rng" : 1.0, "hs_m" : 0.25, "hs_m_rng" : 1.0, "hs_y" : 0.35, "hs_y_rng" : 0.5 }]
// 
// @ART-preset: ["look_dystopic", "$CTL_ODRT_LOOK_DYSTOPIC;Look - Dystopic", { "tn_con" : 1.6, "tn_sh" : 0.5, "tn_toe" : 0.01, "tn_off" : 0.008, "tn_hcon_enable" : true, "tn_hcon" : 0.25, "tn_hcon_pv" : 0.0, "tn_hcon_st" : 1.0, "tn_lcon_enable" : true, "tn_lcon" : 1.0, "tn_lcon_w" : 0.75, "cwp" : 2, "cwp_lm" : 0.25, "rs_sa" : 0.35, "rs_rw" : 0.25, "rs_bw" : 0.55, "pt_enable" : true, "pt_lml" : 0.0, "pt_lml_r" : 0.25, "pt_lml_g" : 0.0, "pt_lml_b" : 0.25, "pt_lmh" : 0.0, "pt_lmh_r" : 0.5, "pt_lmh_b" : 0.0, "ptl_enable" : true, "ptl_c" : 0.05, "ptl_m" : 0.08, "ptl_y" : 0.05, "ptm_enable" : true, "ptm_low" : 0.25, "ptm_low_rng" : 0.25, "ptm_low_st" : 0.8, "ptm_high" : -0.8, "ptm_high_rng" : 0.8, "ptm_high_st" : 0.25, "brl_enable" : true, "brl" : -2.0, "brl_r" : -3.0, "brl_g" : -2.0, "brl_b" : -2.0, "brl_rng" : 0.35, "brl_st" : 0.35, "brlp_enable" : true, "brlp" : 0.0, "brlp_r" : -1.0, "brlp_g" : -1.0, "brlp_b" : -1.0, "hc_enable" : true, "hc_r" : 1.0, "hc_r_rng" : 0.25, "hs_rgb_enable" : true, "hs_r" : 0.7, "hs_r_rng" : 1.33, "hs_g" : 1.0, "hs_g_rng" : 2.0, "hs_b" : 0.75, "hs_b_rng" : 2.0, "hs_cmy_enable" : true, "hs_c" : 1.0, "hs_c_rng" : 0.5, "hs_m" : 1.0, "hs_m_rng" : 1.0, "hs_y" : 1.0, "hs_y_rng" : 0.77 }]
// 
// @ART-preset: ["look_umbra", "$CTL_ODRT_LOOK_UMBRA;Look - Umbra", { "tn_con" : 1.8, "tn_sh" : 0.5, "tn_toe" : 0.001, "tn_off" : 0.015, "tn_hcon_enable" : false, "tn_hcon" : 0.0, "tn_hcon_pv" : 1.0, "tn_hcon_st" : 4.0, "tn_lcon_enable" : true, "tn_lcon" : 1.0, "tn_lcon_w" : 1.0, "cwp" : 5, "cwp_lm" : 0.25, "rs_sa" : 0.35, "rs_rw" : 0.25, "rs_bw" : 0.55, "pt_enable" : true, "pt_lml" : 0.0, "pt_lml_r" : 0.5, "pt_lml_g" : 0.0, "pt_lml_b" : 0.15, "pt_lmh" : 0.25, "pt_lmh_r" : 0.25, "pt_lmh_b" : 0.0, "ptl_enable" : true, "ptl_c" : 0.05, "ptl_m" : 0.06, "ptl_y" : 0.05, "ptm_enable" : true, "ptm_low" : 0.4, "ptm_low_rng" : 0.35, "ptm_low_st" : 0.66, "ptm_high" : -0.5, "ptm_high_rng" : 0.5, "ptm_high_st" : 0.35, "brl_enable" : true, "brl" : -2.0, "brl_r" : -4.5, "brl_g" : -3.0, "brl_b" : -4.0, "brl_rng" : 0.35, "brl_st" : 0.3, "brlp_enable" : true, "brlp" : 0.0, "brlp_r" : -2.0, "brlp_g" : -1.0, "brlp_b" : -0.5, "hc_enable" : true, "hc_r" : 1.0, "hc_r_rng" : 0.35, "hs_rgb_enable" : true, "hs_r" : 0.66, "hs_r_rng" : 1.0, "hs_g" : 0.5, "hs_g_rng" : 2.0, "hs_b" : 0.85, "hs_b_rng" : 2.0, "hs_cmy_enable" : true, "hs_c" : 0.0, "hs_c_rng" : 1.0, "hs_m" : 0.25, "hs_m_rng" : 1.0, "hs_y" : 0.66, "hs_y_rng" : 0.66 }]
// 
// @ART-preset: ["look_base", "$CTL_ODRT_LOOK_BASE;Look - Base", { "tn_con" : 1.66, "tn_sh" : 0.5, "tn_toe" : 0.003, "tn_off" : 0.005, "tn_hcon_enable" : false, "tn_hcon" : 0.0, "tn_hcon_pv" : 1.0, "tn_hcon_st" : 4.0, "tn_lcon_enable" : false, "tn_lcon" : 0.0, "tn_lcon_w" : 0.5, "cwp" : 2, "cwp_lm" : 0.25, "rs_sa" : 0.35, "rs_rw" : 0.25, "rs_bw" : 0.55, "pt_enable" : true, "pt_lml" : 0.5, "pt_lml_r" : 0.5, "pt_lml_g" : 0.15, "pt_lml_b" : 0.15, "pt_lmh" : 0.8, "pt_lmh_r" : 0.5, "pt_lmh_b" : 0.0, "ptl_enable" : true, "ptl_c" : 0.05, "ptl_m" : 0.06, "ptl_y" : 0.05, "ptm_enable" : false, "ptm_low" : 0.0, "ptm_low_rng" : 0.5, "ptm_low_st" : 0.5, "ptm_high" : 0.0, "ptm_high_rng" : 0.5, "ptm_high_st" : 0.5, "brl_enable" : false, "brl" : 0.0, "brl_r" : 0.0, "brl_g" : 0.0, "brl_b" : 0.0, "brl_rng" : 0.5, "brl_st" : 0.35, "brlp_enable" : true, "brlp" : -0.5, "brlp_r" : -1.6, "brlp_g" : -1.6, "brlp_b" : -0.8, "hc_enable" : false, "hc_r" : 0.0, "hc_r_rng" : 0.25, "hs_rgb_enable" : false, "hs_r" : 0.0, "hs_r_rng" : 1.0, "hs_g" : 0.0, "hs_g_rng" : 1.0, "hs_b" : 0.0, "hs_b_rng" : 1.0, "hs_cmy_enable" : false, "hs_c" : 0.0, "hs_c_rng" : 1.0, "hs_m" : 0.0, "hs_m_rng" : 1.0, "hs_y" : 0.0, "hs_y_rng" : 1.0 }]
//
// @ART-preset: ["tonescale_low_contrast", "$CTL_ODRT_TONESCALE_LOW_CONTRAST;Tonescale - Low Contrast", { "tn_con" : 1.4, "tn_sh" : 0.5, "tn_toe" : 0.003, "tn_off" : 0.005, "tn_hcon_enable" : false, "tn_hcon" : 0.0, "tn_hcon_pv" : 1.0, "tn_hcon_st" : 4.0, "tn_lcon_enable" : false, "tn_lcon" : 0.0, "tn_lcon_w" : 0.5 }]
//
// @ART-preset: ["tonescale_medium_contrast", "$CTL_ODRT_TONESCALE_MEDIUM_CONTRAST;Tonescale - Medium Contrast", { "tn_con" : 1.66, "tn_sh" : 0.5, "tn_toe" : 0.003, "tn_off" : 0.005, "tn_hcon_enable" : false, "tn_hcon" : 0.0, "tn_hcon_pv" : 1.0, "tn_hcon_st" : 4.0, "tn_lcon_enable" : false, "tn_lcon" : 0.0, "tn_lcon_w" : 0.5 }]
//
// @ART-preset: ["tonescale_high_contrast", "$CTL_ODRT_TONESCALE_HIGH_CONTRAST;Tonescale - High Contrast", { "tn_con" : 1.4, "tn_sh" : 0.5, "tn_toe" : 0.003, "tn_off" : 0.005, "tn_hcon_enable" : false, "tn_hcon" : 0.0, "tn_hcon_pv" : 1.0, "tn_hcon_st" : 4.0, "tn_lcon_enable" : true, "tn_lcon" : 1.0, "tn_lcon_w" : 0.5 }]
//
// @ART-preset: ["tonescale_arriba", "$CTL_ODRT_TONESCALE_ARRIBA;Tonescale - Arriba", { "tn_con" : 1.05, "tn_sh" : 0.5, "tn_toe" : 0.1, "tn_off" : 0.01, "tn_hcon_enable" : false, "tn_hcon" : 0.0, "tn_hcon_pv" : 1.0, "tn_hcon_st" : 4.0, "tn_lcon_enable" : true, "tn_lcon" : 1.5, "tn_lcon_w" : 0.2 }]
//
// @ART-preset: ["tonescale_sylvan", "$CTL_ODRT_TONESCALE_SYLVAN;Tonescale - Sylvan", { "tn_con" : 1.6, "tn_sh" : 0.5, "tn_toe" : 0.01, "tn_off" : 0.01, "tn_hcon_enable" : false, "tn_hcon" : 0.0, "tn_hcon_pv" : 1.0, "tn_hcon_st" : 4.0, "tn_lcon_enable" : true, "tn_lcon" : 0.25, "tn_lcon_w" : 0.75 }]
//
// @ART-preset: ["tonescale_colorful", "$CTL_ODRT_TONESCALE_COLORFUL;Tonescale - Colorful", { "tn_con" : 1.5, "tn_sh" : 0.5, "tn_toe" : 0.003, "tn_off" : 0.003, "tn_hcon_enable" : false, "tn_hcon" : 0.0, "tn_hcon_pv" : 1.0, "tn_hcon_st" : 4.0, "tn_lcon_enable" : true, "tn_lcon" : 0.4, "tn_lcon_w" : 0.5 }]
//
// @ART-preset: ["tonescale_aery", "$CTL_ODRT_TONESCALE_AERY;Tonescale - Aery", { "tn_con" : 1.15, "tn_sh" : 0.5, "tn_toe" : 0.04, "tn_off" : 0.006, "tn_hcon_enable" : false, "tn_hcon" : 0.0, "tn_hcon_pv" : 0.0, "tn_hcon_st" : 0.5, "tn_lcon_enable" : true, "tn_lcon" : 0.5, "tn_lcon_w" : 2.0 }]
//
// @ART-preset: ["tonescale_dystopic", "$CTL_ODRT_TONESCALE_DYSTOPIC;Tonescale - Dystopic", { "tn_con" : 1.6, "tn_sh" : 0.5, "tn_toe" : 0.01, "tn_off" : 0.008, "tn_hcon_enable" : true, "tn_hcon" : 0.25, "tn_hcon_pv" : 0.0, "tn_hcon_st" : 1.0, "tn_lcon_enable" : true, "tn_lcon" : 1.0, "tn_lcon_w" : 0.75 }]
//
// @ART-preset: ["tonescale_umbra", "$CTL_ODRT_TONESCALE_UMBRA;Tonescale - Umbra", { "tn_con" : 1.8, "tn_sh" : 0.5, "tn_toe" : 0.001, "tn_off" : 0.015, "tn_hcon_enable" : false, "tn_hcon" : 0.0, "tn_hcon_pv" : 1.0, "tn_hcon_st" : 4.0, "tn_lcon_enable" : true, "tn_lcon" : 1.0, "tn_lcon_w" : 1.0 }]
//
// @ART-preset: ["tonescale_aces1", "$CTL_ODRT_TONESCALE_ACES_1_X;Tonescale - ACES-1.x", { "tn_con" : 1.0, "tn_sh" : 0.35, "tn_toe" : 0.02, "tn_off" : 0.0, "tn_hcon_enable" : true, "tn_hcon" : 0.55, "tn_hcon_pv" : 0.0, "tn_hcon_st" : 2.0, "tn_lcon_enable" : true, "tn_lcon" : 1.13, "tn_lcon_w" : 1.0 }]
//
// @ART-preset: ["tonescale_aces2", "$CTL_ODRT_TONESCALE_ACES_2_0;Tonescale - ACES-2.0", { "tn_con" : 1.15, "tn_sh" : 0.5, "tn_toe" : 0.04, "tn_off" : 0.0, "tn_hcon_enable" : false, "tn_hcon" : 1.0, "tn_hcon_pv" : 1.0, "tn_hcon_st" : 1.0, "tn_lcon_enable" : false, "tn_lcon" : 1.0, "tn_lcon_w" : 0.6 }]
//
// @ART-preset: ["tonescale_marvelous", "$CTL_ODRT_TONESCALE_MARVELOUS_TONESCAPE;Tonescale - Marvelous Tonescape", { "tn_con" : 1.5, "tn_sh" : 0.5, "tn_toe" : 0.003, "tn_off" : 0.01, "tn_hcon_enable" : true, "tn_hcon" : 0.25, "tn_hcon_pv" : 0.0, "tn_hcon_st" : 4.0, "tn_lcon_enable" : true, "tn_lcon" : 1.0, "tn_lcon_w" : 1.0 }]
//
// @ART-preset: ["tonescale_dagrinchi", "$CTL_ODRT_TONESCALE_DAGRINCHI_TONEGROAN;Tonescale - DaGrinchi Tonegroan", { "tn_con" : 1.2, "tn_sh" : 0.5, "tn_toe" : 0.02, "tn_off" : 0.0, "tn_hcon_enable" : false, "tn_hcon" : 0.0, "tn_hcon_pv" : 1.0, "tn_hcon_st" : 1.0, "tn_lcon_enable" : false, "tn_lcon" : 0.0, "tn_lcon_w" : 0.6 }]

void ART_main(varying float r, varying float g, varying float b,
              output varying float rout,
              output varying float gout,
              output varying float bout,
              float ex,
              float tn_Lp,
              float tn_gb,
              float pt_hdr,
              float tn_Lg,

              float tn_con,
              float tn_sh,
              float tn_toe,
              float tn_off,
              bool tn_hcon_enable,
              float tn_hcon,
              float tn_hcon_pv,
              float tn_hcon_st,
              bool tn_lcon_enable,
              float tn_lcon,
              float tn_lcon_w,
              int cwp,
              float cwp_lm,
              float rs_sa,
              float rs_rw,
              float rs_bw,
              bool pt_enable,
              float pt_lml,
              float pt_lml_r,
              float pt_lml_g,
              float pt_lml_b,
              float pt_lmh,
              float pt_lmh_r,
              float pt_lmh_b,
              bool ptl_enable,
              float ptl_c,
              float ptl_m,
              float ptl_y,
              bool ptm_enable,
              float ptm_low,
              float ptm_low_rng,
              float ptm_low_st,
              float ptm_high,
              float ptm_high_rng,
              float ptm_high_st,
              bool brl_enable,
              float brl,
              float brl_r,
              float brl_g,
              float brl_b,
              float brl_rng,
              float brl_st,
              bool brlp_enable,
              float brlp,
              float brlp_r,
              float brlp_g,
              float brlp_b,
              bool hc_enable,
              float hc_r, 
              float hc_r_rng,
              bool hs_rgb_enable,
              float hs_r,
              float hs_r_rng,
              float hs_g, 
              float hs_g_rng,
              float hs_b, 
              float hs_b_rng,
              bool hs_cmy_enable,
              float hs_c,
              float hs_c_rng,
              float hs_m, 
              float hs_m_rng,
              float hs_y, 
              float hs_y_rng, 

              int tn_su,
              int display_gamut
    )
{
  /* `ex` is a user controlled exposure adjustment.
      For the tonescale presets where tn_Lg=0.111, the default value of ex=0.697437 sets middle grey 
      so that "scene-linear" input value 0.18 maps to a "display-linear" output value of 0.18.
      Put another way: The image formation algorithm does not change the position of middle grey.
      OpenDRT is targeted more towards video workflows, where it is more common for middle grey to be
      placed following the Rec.709 OETF, which is why many of the tonescale presets map 0.18 to 0.111.
      This exposure control's default value is meant to compensate for the expectations of still photography, 
      where it might be confusing for overall image exposure to be changed by the image formation transform.
      Having the default value be non-zero still allows the user to set the exposure value to 0 and
      match the OpenDRT presets exactly if desired.
  */
  const float gain = pow(2.0, ex);
  const int eotf = 0;

  float3 rgb = transform(r * gain, g * gain, b * gain,
                         4,
                         tn_hcon_enable,
                         tn_lcon_enable,
                         pt_enable,
                         ptl_enable,
                         ptm_enable,
                         brl_enable,
                         brlp_enable,
                         hc_enable,
                         hs_rgb_enable,
                         hs_cmy_enable,
                         cwp,
                         tn_su,
                         1,
                         display_gamut,
                         eotf,
                         tn_con,
                         tn_sh,
                         tn_toe,
                         tn_off,
                         tn_hcon,
                         tn_hcon_pv,
                         tn_hcon_st,
                         tn_lcon,
                         tn_lcon_w,
                         cwp_lm,
                         rs_sa,
                         rs_rw,
                         rs_bw,
                         pt_lml,
                         pt_lml_r,
                         pt_lml_g,
                         pt_lml_b,
                         pt_lmh,
                         pt_lmh_r,
                         pt_lmh_b,
                         ptl_c,
                         ptl_m,
                         ptl_y,
                         ptm_low,
                         ptm_low_rng,
                         ptm_low_st,
                         ptm_high,
                         ptm_high_rng,
                         ptm_high_st,
                         brl,
                         brl_r,
                         brl_g,
                         brl_b,
                         brl_rng,
                         brl_st,
                         brlp,
                         brlp_r,
                         brlp_g,
                         brlp_b,
                         hc_r,
                         hc_r_rng,
                         hs_r,
                         hs_r_rng,
                         hs_g,
                         hs_g_rng,
                         hs_b,
                         hs_b_rng,
                         hs_c,
                         hs_c_rng,
                         hs_m,
                         hs_m_rng,
                         hs_y,
                         hs_y_rng,
                         tn_Lp,
                         tn_gb,
                         pt_hdr,
                         tn_Lg);

  if (display_gamut == 0) {
      rgb = vdot(matrix_xyz_to_rec2020, vdot(matrix_rec709_to_xyz, rgb));
  } else if (display_gamut == 1) {
    rgb = vdot(matrix_xyz_to_rec2020, vdot(matrix_p3d65_to_xyz, rgb));
  }

  float outscale = tn_Lp / 100.0;

  rout = rgb.x * outscale;
  gout = rgb.y * outscale;
  bout = rgb.z * outscale;
}
