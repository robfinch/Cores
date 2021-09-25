#include "stdafx.h"

extern int countLeadingBits(int64_t val);
extern double clog2(double n);

int64_t Posit32::posWidth = 32;
int64_t Posit32::expWidth = 2;

Posit32::Posit32(int i)
{
  val = 0;
  IntToPosit(i);
}

Posit32 Posit32::Addsub(int8_t op, Posit32 a, Posit32 b)
{
  int64_t rs = (int64_t)clog2((double)(posWidth - 1LL));
  int64_t es = expWidth;
  int64_t sa, sb, so;
  int8_t rop;
  int64_t rgma, rgmb, rgm1, rgm2, argm1, argm2;
  int64_t absrgm1;
  int8_t rgsa, rgsb, rgs1, rgs2;
  int64_t diff;
  int64_t expa, expb, exp1, exp2;
  int64_t exp_diff;
  uint64_t siga, sigb, sig1, sig2;
  uint64_t sigi;
  Int128 sig1s, sig2s, sig_sd, sig_ls, t1, t2;
  int8_t zera, zerb;
  int8_t infa, infb;
  int8_t sigov;
  int64_t lzcnt;
  int64_t aa, bb;
  bool aa_gt_bb;
  int8_t inf, zero;
  int64_t rxtmp, rxtmp1, srxtmp1, abs_rxtmp;
  int64_t rgmo;
  int64_t expo;
  int64_t exp_mask = (((uint64_t)1 << (uint64_t)expWidth) - 1LL);
  int64_t rs_mask = (((uint64_t)1 << (uint64_t)rs) - 1LL);
  RawPosit ad((int8_t)2, (int8_t)32), bd((int8_t)2, (int8_t)32);
  int64_t S, T, L, G, R, St, St1;
  Int256 s1, s2;
  int nn;
  uint64_t ulp, rnd_ulp, tmp1_rnd_ulp, tmp1_rnd;
  uint64_t abs_tmp, o;
  Posit32 out;
  uint64_t sx;

  Decompose(a, &ad);
  sa = ad.sign;
  rgsa = ad.regsign;
  rgma = ad.regime;
  expa = ad.exp;
  siga = ad.sig.low;
  zera = ad.isZero;
  infa = ad.isInf;

  Decompose(b, &bd);
  sb = bd.sign;
  rgsb = bd.regsign;
  rgmb = bd.regime;
  expb = bd.exp;
  sigb = bd.sig.low;
  zerb = bd.isZero;
  infb = bd.isInf;

  inf = infa | infb;
  zero = zera & zerb;
  aa = sa ? -a.val : a.val;
  bb = sb ? -b.val : b.val;
  aa_gt_bb = aa >= bb;

  // Determine op really wanted
  rop = sa ^ sb ^ op;

  // Sort operand components
  rgs1 = aa_gt_bb ? rgsa : rgsb;
  rgs2 = aa_gt_bb ? rgsb : rgsa;
  rgm1 = aa_gt_bb ? rgma : rgmb;
  rgm2 = aa_gt_bb ? rgmb : rgma;
  exp1 = aa_gt_bb ? expa : expb;
  exp2 = aa_gt_bb ? expb : expa;
  sig1 = aa_gt_bb ? siga : sigb;
  sig2 = aa_gt_bb ? sigb : siga;

  argm1 = rgs1 ? rgm1 : -rgm1;
  argm2 = rgs2 ? rgm2 : -rgm2;

  sig1 = sig1 << 3LL;
  sig2 = sig2 << 3LL;
  
  // ???
  argm1 = argm1 < 0 ? argm1 + 2 : argm1;
  argm2 = argm2 < 0 ? argm2 + 2 : argm2;

  diff = ((argm1 << expWidth) | exp1) - ((argm2 << expWidth) | exp2);
  exp_diff = (diff > ((1LL << (rs + 1LL))) -1LL) ? -1LL & rs_mask : diff & rs_mask;
  sig1s.low = 0;
  sig1s.high = sig1 << 32;
  sig2s.low = 0;
  sig2s.high = sig2 << 32;
  Int128::Lsr(&sig2s, &sig2s, exp_diff);
  if (rop)
    sigov = Int128::Sub(&sig_sd, &sig1s, &sig2s);
  else
    sigov = Int128::Add(&sig_sd, &sig1s, &sig2s);
  sigi = sig_sd.high;
  if (sigov) {
    Int128::Lsr(&sig_sd, &sig_sd, 1LL);
    sig_sd.high |= 0x8000000000000000LL;
    sigi = sig_sd.low | (1LL << 63LL);
  }
  lzcnt = countLeadingZeros(sigi);
  Int128::Shl(&sig_ls, &sig_sd, lzcnt);
  absrgm1 = rgs1 ? rgm1 : -rgm1;  // rgs1 = 1 = positive
  if (expWidth > 0) {
    rxtmp = ((absrgm1 << (int64_t)expWidth) | exp1) - lzcnt;
    rxtmp1 = rxtmp + sigov; // add in overflow if any
    srxtmp1 = (((uint64_t)rxtmp1 >> (int64_t)(expWidth + rs + 1LL)) & 1LL);
    abs_rxtmp = srxtmp1 ? -rxtmp1 : rxtmp1;
    if (srxtmp1 && ((abs_rxtmp & exp_mask) != 0))
      expo = rxtmp1 & exp_mask;
    else
      expo = abs_rxtmp & exp_mask;
    if (~srxtmp1 || ((abs_rxtmp & exp_mask) != 0LL))
      rgmo = ((abs_rxtmp >> expWidth) & rs_mask) + 1LL;
    else
      rgmo = ((abs_rxtmp >> expWidth) & rs_mask);
  }
  else {
    rxtmp = absrgm1 - lzcnt;
    rxtmp1 = rxtmp + (sigov >> 1LL);   // add in overflow if any
    srxtmp1 = (rxtmp1 >> (rs + 1LL)) & 1LL;
    abs_rxtmp = srxtmp1 ? -rxtmp1 : rxtmp1;
    expo = 0;
    rgmo = ~srxtmp1 ? (abs_rxtmp & rs_mask) + 1LL : abs_rxtmp & rs_mask;
  }
  int64_t srxx = srxtmp1 ? 0LL : -1LL;

  // Exponent and Significand Packing
  s1 = *s1.Zero();
  switch (es) {
  case 0:
    S = sig_ls.StickyCalc(posWidth*2 - 3);
    s1.low = srxx;
    s1.midLow = srxx;
    s1.midHigh = srxx;
    s1.high = srxx;
    s1.insert(S, 0, 1);
    s1.insert(sig_ls.extract(posWidth*3 - 2, 32), 1, 32);
    s1.insert(sig_ls.extract(posWidth*3 + 30, 1), 33, 1);
    s1.insert(srxtmp1, 34, 1);
    break;
  case 1:
    S = sig_ls.StickyCalc(posWidth*2 - 2);
    s1.low = srxx;
    s1.midLow = srxx;
    s1.midHigh = srxx;
    s1.high = srxx;
    s1.insert(S, 0, 1);
    s1.insert(sig_ls.extract(posWidth*3 - 1, 32), 1, 32);
    s1.insert(expo, 33, 1);
    s1.insert(srxtmp1, 34, 1);
    break;
  case 2:
    S = sig_ls.StickyCalc(posWidth*3 - 1);
    s1.low = srxx;
    s1.midLow = srxx;
    s1.midHigh = srxx;
    s1.high = srxx;
    s1.insert(S, 0, 1);
    s1.insert(sig_ls.extract(posWidth*3, 31), 1, 31);
    s1.insert(expo, 32, 2);
    s1.insert(srxtmp1, 34, 1);
    break;
  case 3:
    S = sig_ls.StickyCalc(posWidth*3);
    s1.low = srxx;
    s1.midLow = srxx;
    s1.midHigh = srxx;
    s1.high = srxx;
    s1.insert(S, 0, 1);
    sx = sig_ls.extract(posWidth*3 + 1, 30);
    s1.insert(sx, 1, 30);
    s1.insert(expo, 31, 3);
    s1.insert(srxtmp1, 34, 1);
    break;
  default:
    // Error: not supported
    S = sig_ls.StickyCalc(posWidth*3 - 1LL + expWidth - 2LL);
    s1.low = srxx;
    s1.midLow = srxx;
    s1.midHigh = srxx;
    s1.high = srxx;
    s1.insert(S, 0, 1);
    s1.insert(sig_ls.extract(posWidth*3+expWidth-3LL, posWidth * 4LL -(posWidth*3 + expWidth - 3LL) ), 1LL, posWidth * 4LL - (posWidth*3 + expWidth - 3LL));
    s1.insert(expo, posWidth * 4LL - 2LL - (posWidth*3 + expWidth - 2LL) + 2LL, expWidth);
    s1.insert(srxtmp1, posWidth * 4LL - 2LL - (posWidth*3 + expWidth - 2LL) + expWidth + 2LL, 1LL);
    break;
  }
  s1.Shl(&s2, & s1, posWidth + 1LL);
  s2.Shr(&s2, & s2, rgmo);

//             wire[3 * PSTWID - 1 + 3:0] tmp1 = { tmp,{PSTWID{1'b0}}} >> rgmo;
// Rounding
// Guard, Round, and Sticky
  L = s2.extract(posWidth + 4, 1);
  G = s2.extract(posWidth + 3, 1);
  R = s2.extract(posWidth + 2, 1);
  St = t1.StickyCalc(posWidth+1);
  ulp = ((G & (R | St)) | (L & G & ~(R | St)));
  tmp1_rnd_ulp = s2.extract(posWidth + 3LL, posWidth);
  t1.low = tmp1_rnd_ulp;
  t1.high = 0;
  t2.low = ulp;
  t2.high = 0;
  Int128::Add(&t1, &t1, &t2);
  t2.low = s2.extract(posWidth + 3, posWidth);
  tmp1_rnd = (rgmo < posWidth - es - 2LL) ? tmp1_rnd_ulp : t2.low;

  // Compute output sign
  switch ((zero << 3LL) | (sa << 2LL) | (op << 1LL) | sb) {
  case 0: so = 0; break;
  case 1: so = !aa_gt_bb; break;
  case 2: so = !aa_gt_bb; break;
  case 3: so = 0; break;
  case 4: so = aa_gt_bb; break;
  case 5: so = 1; break;
  case 6: so = 1; break;
  case 7: so = aa_gt_bb; break;
  default: so = 0; break;
  }

  abs_tmp = so ? ~tmp1_rnd + 1LL : tmp1_rnd;

  switch ((zero << 2LL) | (inf << 1LL) | (sig_ls.high & 1LL & 0)) {
  case 0: o = (so << 63LL) | (abs_tmp >> 1LL); break;
  case 1: o = 0; break;
  case 2:
  case 3: o = (1LL << 63LL); break;
  case 4:
  case 5:
  case 6:
  case 7: o = 0; break;
  }
  out.val = o;
  return (out);
}


Posit32 Posit32::Add(Posit32 a, Posit32 b)
{
  return (Addsub(0, a, b));
}

Posit32 Posit32::Sub(Posit32 a, Posit32 b)
{
  return (Addsub(1, a, b));
}

Posit32 Posit32::Multiply(Posit32 a, Posit32 b)
{
  Posit32Multiplier pm;
  return (pm.Multiply(a, b));
};

Posit32 Posit32Multiplier::Round(Int256 tmp1, int rgml, uint64_t so, bool zero, bool inf)
{
  Posit32 out;

  int64_t M = posWidth - expWidth;
  int64_t L = tmp1.extract(posWidth + 4, 1);
  int64_t G = tmp1.extract(posWidth + 3, 1);
  int64_t R = tmp1.extract(posWidth + 2, 1);
  int64_t St = tmp1.StickyCalc(&tmp1, posWidth + 1);
  int64_t ulp = ((G & (R | St)) | (L & G & ~(R | St)));
  int64_t tmp1_rnd_ulp = tmp1.extract(posWidth + 3, posWidth) + ulp;
  int64_t c = tmp1.AddCarry(tmp1_rnd_ulp, tmp1.extract(posWidth + 3, posWidth), ulp);
  int64_t tmp1_rnd = (rgml < M - 2LL) ? tmp1_rnd_ulp : tmp1.extract(posWidth + 3, posWidth);
  int64_t abs_tmp = so ? -tmp1_rnd : tmp1_rnd;
  out.val = zero ? 0LL : inf ? 0x8000000000000000LL : (so << 63LL) | ((uint64_t)abs_tmp >> 1LL);
  return (out);
}

Int256 Posit32Multiplier::BuildResult(Int128 prod1, int64_t exp, int64_t rs)
{
  Int256 tmp;
  int64_t M = posWidth - expWidth;
  uint64_t fldw = M + 1LL;  // hide leading bit (extract started at offset -2)
  uint64_t ext = prod1.extract(M - 2LL, fldw);
  int64_t srxx = rs ? 0LL : -1LL;

  tmp.low = srxx;
  tmp.midLow = srxx;
  tmp.midHigh = srxx;
  tmp.high = srxx;
  tmp.insert(prod1.StickyCalc(M - 3LL), 0LL, 1LL);
  tmp.insert(ext, 1LL, fldw);
  tmp.insert(exp, fldw + 1LL, expWidth);
  tmp.insert(rs, fldw + 1LL + expWidth, 1LL);
  return (tmp);
}

Posit32 Posit32Multiplier::Multiply(Posit32 a, Posit32 b)
{
  RawPosit rawA(3, 64);
  RawPosit rawB(3, 64);
  RawPosit rawP(3, 64);
  Int128 prod, prod1;
  int64_t argma, argmb;
  int64_t M = posWidth - expWidth;
  int64_t mo;
  int64_t rs = clog2(posWidth - 1);
  Posit32 o;
  int64_t decexp;
  int64_t sigw, one;
  int cnt;
  Int128 mask;
  int64_t expMask = (1LL << expWidth) - 1LL;

  Decompose(a, &rawA);
  Decompose(b, &rawB);
  int64_t inf = rawA.isInf | rawB.isInf;
  int64_t zero = rawA.isZero | rawB.isZero;
  if (zero) {
    o.val = 0;
    return (o);
  }
  else if (inf) {
    o.val = 0x8000000000000000LL;
    return (o);
  }
  int64_t so = rawA.sign ^ rawB.sign;
  sigw = (int64_t)rawA.sigWidth + (int64_t)rawB.sigWidth;
  one = 1LL << (sigw - 64);
  rawP.isNaR = rawA.isNaR || rawB.isNaR;
  rawP.isInf = rawA.isInf || rawB.isInf;
  rawP.isZero = rawA.isZero || rawB.isZero;
  rawP.sign = rawA.sign ^ rawB.sign;
  rawP.regexp = rawA.regexp + rawB.regexp;

  // Generate product and align result
  Int128::Mul(&rawP.sig, &rawA.sig, &rawB.sig);
  mo = rawP.sig.Int128::extract(M * 2LL - 1LL, 1LL);
  if (mo)
    Int128::Assign(&prod1, &rawP.sig);
  else {
    Int128::Shl(&prod1, &rawP.sig, 1LL);
  }
  mask = Int128::MakeMask(2LL * M);
  prod1.BitAnd(&prod1, &prod1, &mask);

  argma = rawA.regsign ? rawA.regime : -rawA.regime;
  argmb = rawB.regsign ? rawB.regime : -rawB.regime;
  int64_t regsign = abs(argma) >= abs(argmb) ? 1LL : 0LL;
  int64_t rxtmp = ((argma << expWidth) | rawA.exp) + ((argmb << expWidth) | rawB.exp) + mo;
  int64_t exp = rxtmp & expMask;
  int64_t srxtmp = ((rxtmp >> (rs + expWidth + 1)) & 1LL);
  int64_t rxtmp2c = srxtmp ? -rxtmp : rxtmp;
  int64_t rgm = rxtmp2c >> expWidth;
  int64_t rxn = srxtmp ? rxtmp2c : rxtmp;
  int64_t rgml = (!srxtmp || ((rxn & expMask) != 0)) ? (rxtmp2c >> expWidth) +1LL : (rxtmp2c >> expWidth);

  // Build result posit
  Int256 tmp;
  tmp = BuildResult(prod1, exp, srxtmp);

  Int256 tmp1;
  Int256::Shl(&tmp1, &tmp, posWidth + (regsign ? 2LL : 0LL));
  Int256::Lsr(&tmp1, &tmp1, rgml + (regsign ? 0LL : 0LL));

  // Rounding
  o = Round(tmp1, rgml, so, zero, inf);
  return (o);
}

Posit32 Posit32::Divide(Posit32 a, Posit32 b)
{
  RawPosit aa(Posit32::expWidth, Posit32::posWidth);
  RawPosit bb(Posit32::expWidth, Posit32::posWidth);
  Posit32 out;
  int64_t so;
  int64_t inf;
  int64_t zer;
  uint64_t m1, m2;
  int64_t m2_inv0_tmp;
  int64_t argma, argmb;
  int64_t M = posWidth - expWidth;
  int64_t Bs = clog2(posWidth - 1LL);
  int8_t NR_Iter;
  int8_t IW_MAX = 16;
  int64_t IW = 16;
  int8_t AW = 16;
  int8_t AW_MAX = 16;
  int64_t m2_inv0;
  Int256 div_m, div_mN, div_mNm;
  int64_t m2_inv_X_m2_64;
  Int256 t1, t2, t3, t4;
  Int256 m2_128, mask1, mask2, mask2mp1;
  Int256 mask, t11, t12;
  int64_t ii, jj;
  int64_t St, tt;
  int64_t div_m_udf;
  int64_t div_e, div_eN;
  int64_t bin;
  int64_t e_o, r_o, ro_s;
  int64_t exp_oN;
  int64_t div_e_mask;
  int64_t tmp_o0, tmp_o1, tmp_o2, tmp_o3;
  Int256 tmp_o, tmp1_o;
  Int256 one;
  Int256 oneScaled;
  int64_t normAmt;
  bool incr = false;

  if (M > IW_MAX*8)
    NR_Iter = 4;
  else if (M > IW_MAX*4)
    NR_Iter = 3;
  else if (M > IW_MAX*2)
    NR_Iter = 2;
  else if (M > IW_MAX)
    NR_Iter = 1;
  else
    NR_Iter = 0;

  Posit32::Decompose(a, &aa);
  Posit32::Decompose(b, &bb);
  inf = aa.isInf | bb.isZero;
  zer = aa.isZero | bb.isInf;
  so = aa.sign ^ bb.sign;
  m1 = (uint64_t)aa.sig.low << 1LL;// >> expWidth;
  m2 = (uint64_t)bb.sig.low << 1LL;// >> expWidth;
  argma = aa.regsign ? aa.regime : -aa.regime;
  argmb = bb.regsign ? bb.regime : -bb.regime;

  if (M < AW_MAX)
    m2_inv0_tmp = DividerLUT[(m2 << (AW_MAX-M)) & 0xFFFFLL];
  else if (M == AW_MAX)
    m2_inv0_tmp = DividerLUT[m2 & 0xFFFFLL];
  else {
    int m2_dlut_ndx = (m2 >> (M - AW_MAX)) & 0xffff;
    m2_inv0_tmp = DividerLUT[m2_dlut_ndx];
  }
  
  Int256 m2_inv[20];
  Int256 m2_inv_X_m2[20];
  Int256 m2_inv_X_m2_norm;
  Int256 m2_inv_X_m2_norm_lim;
  Int256 m2_inv_norm; // normalized m2_inv[]
  Int256 m2_inv_placed;
  Int256 one_placed;
  Int256 two_m2_inv_X_m2[20];
  Int256 two_m2_inv_X_m2_ext;
  Int256 two_m2_inv_X_m2_lim;

  m2_inv0 = m2_inv0_tmp;
  mask2mp1 = Int256::MakeMask(2LL * M + 2LL);
  Int256 maskmp1 = Int256::MakeMask(M + 2LL);
  Int256 maskm = Int256::MakeMask(M + 1LL);
  Int256 maskmm2 = Int256::MakeMask(M - 1LL);
  if (NR_Iter > 0) {
    m2_inv[0] = *Int256::Zero();
    m2_inv[0].insert(m2_inv0, 2LL*M - IW, IW + 1LL);    // 2M value
    m2_128 = Int256::Convert(m2);
    for (ii = 0; ii < NR_Iter; ii++) {

      // assign m2_inv_X_m2[i] = {m2_inv[i][2*M:2*M-IW*(i+1)],{2*M-IW*(i+1)-M{1'b0}}} * m2d;
      Int256::Lsr(&m2_inv_norm, &m2_inv[ii], 2LL * M - (IW * (ii + 1LL)));
      mask = Int256::MakeMask((IW + 1LL) * (ii + 1LL));
      m2_inv_norm.BitAnd(&m2_inv_norm, &m2_inv_norm, &mask);
      Int256::Shl(&m2_inv_placed, &m2_inv_norm, M - (IW * (ii + 1LL)));
      Int256::Mul(&m2_inv_X_m2[ii], &m2_inv_placed, &m2_128);
      m2_inv_X_m2[ii].BitAnd(&m2_inv_X_m2[ii], &m2_inv_X_m2[ii], &mask2mp1);

      // assign two_m2_inv_X_m2[i] = {1'b1,{M{1'b0}}} - {1'b0,m2_inv_X_m2[i][2*M+1:M+3],|m2_inv_X_m2[i][M+2:0]};
      St = m2_inv_X_m2[ii].StickyCalc(&m2_inv_X_m2[ii], M + 2LL);
      Int256::Lsr(&m2_inv_X_m2_norm, &m2_inv_X_m2[ii], M + 3LL);
      m2_inv_X_m2_norm_lim.BitAnd(&m2_inv_X_m2_norm_lim, &m2_inv_X_m2_norm, &maskmm2);
      Int256::Shl(&m2_inv_X_m2_norm_lim, &m2_inv_X_m2_norm_lim, 1LL);
      m2_inv_X_m2_norm_lim.low |= St;
      one = Int256::Convert(1LL);
      Int256::Shl(&one_placed, &one, M);
      Int256::Sub(&two_m2_inv_X_m2[ii], &one_placed, &m2_inv_X_m2_norm_lim);
      two_m2_inv_X_m2[ii].BitAnd(&two_m2_inv_X_m2[ii], &two_m2_inv_X_m2[ii], &maskmp1);

      // assign m2_inv[i + 1] = { m2_inv[i][2 * M:2 * M - IW * (i + 1)],{M - IW * (i + 1) { 1'b0}}} * {two_m2_inv_X_m2[i][M-1:0],1'b0 };
      two_m2_inv_X_m2_ext = *Int256::Zero();
      two_m2_inv_X_m2_ext.low = two_m2_inv_X_m2[ii].extract(0LL, M);
      Int256::Shl(&two_m2_inv_X_m2_ext, &two_m2_inv_X_m2_ext, 1LL);
      Int256::Mul(&m2_inv[ii + 1], &m2_inv_placed, &two_m2_inv_X_m2_ext);
      m2_inv[ii + 1].BitAnd(&m2_inv[ii + 1], &m2_inv[ii + 1], &mask2mp1);
    }
  }
  else {
    m2_inv[0] = Int256::Convert(m2_inv0);
    Int256::Shl(&m2_inv[0], &m2_inv[0], M);
    m2_inv[0].BitAnd(&m2_inv[0], &m2_inv[0], &mask2mp1);
  }

  tt = ((bb.sig.low << 1) & ((1LL << (M - 2LL)) - 1LL)) == 0;

  t2 = *Int256::Zero();
  t2.low = m1;
  t4 = *Int256::Zero();
  t4.low = m1;
  Int256::Shl(&t4, &t4, M);
  Int256::Lsr(&t3, &m2_inv[NR_Iter], M);
  mask = Int256::MakeMask(M + 1LL);
  t3.BitAnd(&t3, &t3, &mask);
  Int256::Mul(&t2, &t2, &t3);

  if (tt) {
    t4 = *Int256::Zero();
    t4.low = m1;
    Int256::Assign(&div_m, &t4);
    Int256::Shl(&div_m, &div_m, M);
  }
  else {
    Int256::Assign(&div_m, &t2);
  }
  Int256::Assign(&div_mN, &div_m);
  bin = 0;
  div_m_udf = div_m.extract(2LL * M + 1LL, 1LL);
  Int256::Shl(&div_mN, &div_mN, div_m_udf == 0LL ? 1LL : 0LL);
  bin = tt || div_m_udf ? bin : bin + 1;
  div_e = ((argma << expWidth) | aa.exp) - ((argmb << expWidth) | bb.exp) - bin;
  e_o = div_e & ((1LL << expWidth) - 1LL);
  div_e_mask = (1LL << (expWidth + Bs + 1LL)) - 1LL;
  exp_oN = ((div_e >> (expWidth + Bs + 1LL)) & 1LL) ? -div_e & div_e_mask : div_e & div_e_mask;
  r_o = (((div_e >> (expWidth + Bs + 1LL)) & 1LL)==0) || (((exp_oN & ((1LL << expWidth)-1LL)) & 1LL)!=0) ? (exp_oN >> expWidth) + 1LL : (exp_oN >> expWidth);

  // Exponent and mantissa packing
  mask = Int256::MakeMask(2LL * M + 2LL);
  div_mNm.BitAnd(&div_mNm, &div_mN, &mask);
  tmp_o = *Int256::Zero();
  tmp_o.insert(div_mNm.Int256::StickyCalc(&div_mNm,M - 1LL), 0LL, 1LL);
  Int256::Lsr(&t11, &div_mNm, M);
  tmp_o.insert(t11, 1LL, M+1LL);
  tmp_o.insert(e_o, M + 2LL, expWidth);
  tmp_o.insert((div_e >> (expWidth + Bs + 1LL)) & 1LL, M + 2LL + expWidth, 1LL);
  if ((div_e >> (expWidth + Bs + 1LL)) & 1LL)
    div_eN = 0LL;
  else
    div_eN = -1LL;
  tmp_o.insert(div_eN, posWidth + 3LL, 64LL);
  Int256::Assign(&tmp1_o, &tmp_o);
  Int256::Shl(&tmp1_o, &tmp1_o, posWidth);
  ro_s = (r_o >> Bs) & 1LL;
  tt = ro_s ? ((1LL << Bs) - 1LL) : r_o;
  Int256::Lsr(&tmp1_o, &tmp1_o, tt);

  // Rounding
  int64_t L = tmp1_o.extract(posWidth + 4, 1LL);
  int64_t G = tmp1_o.extract(posWidth + 3, 1LL);
  int64_t R = tmp1_o.extract(posWidth + 2, 1LL);
  St = tmp1_o.StickyCalc(&tmp1_o, posWidth + 1);
  int64_t ulp = ((G & (R | St)) | (L & G & ~(R | St)));
  int64_t tmp1_o_rnd_ulp = tmp1_o.extract(posWidth+3LL,posWidth) + ulp;
  int64_t c = Int256::AddCarry(tmp1_o_rnd_ulp, tmp1_o.low, ulp);
  int64_t tmp1_o_rnd = (r_o < (M - 2LL)) ? tmp1_o_rnd_ulp : tmp1_o.extract(posWidth + 3LL, posWidth);

  // Final Output
  int64_t tmp1_oN = so ? -tmp1_o_rnd : tmp1_o_rnd;
  int64_t o = inf || zer || (div_mNm.extract(M*2LL+1LL,1LL)==0) ? (inf << (posWidth - 1LL)) : (so << (posWidth - 1LL)) | ((uint64_t)tmp1_oN >> 1LL);
  out.val = o;
  return (out);
}


Posit32 Posit32::IntToPosit(int64_t i)
{
  int8_t sgn;
  int64_t ii;
  int8_t lzcnt;
  int8_t rgm, rgm_sh;
  uint64_t sig;
  int8_t exp;
  Int128 tmp, tmp1, tmp2, tmp3, tmp2_rnd;
  int64_t ones;
  Int128 L, G, R;
  int64_t S;
  int64_t nn;
  int64_t rnd_ulp;
  Posit32 pst;

  if (i == 0) {
    pst.val = 0;
    return (pst);
  }
  ii = i < 0 ? -i : i;
  lzcnt = countLeadingZeros((ii<<1LL)|1LL);
  sgn = (i >> posWidth-1LL) & 1LL;
  rgm = (posWidth - (lzcnt + 2LL)) >> expWidth;
  sig = ii << lzcnt;  // left align number
  sig &= 0x3fffffff;  // chop off leading one
  if (expWidth > 0) {
    exp = (posWidth - (lzcnt + 2LL)) & ((1LL << expWidth) - 1LL);
    ones = -1LL;
    //ones <<= ((expWidth + 1LL) + 1LL);
    tmp.low = 0;
    tmp.high = 0;
    tmp.insert(sig, 3LL, posWidth - 2LL);
    tmp.insert(exp, posWidth + 1LL, expWidth);
    tmp.insert(ones, posWidth + expWidth + 2LL, posWidth);
    //tmp.low = sig << 3LL;
    //tmp.high = (sig >> 63LL) | (exp << 1LL) | ones;
  }
  else {
    ones = -1LL;
    //ones <<= (1 + 1);
    //tmp.low = sig << 3LL;
    //tmp.high = (sig >> 63LL) | ones;
    tmp.low = 0;
    tmp.high = 0;
    tmp.insert(sig, 3LL, posWidth - 3LL);
    tmp.insert(ones, posWidth + 1LL, posWidth);
  }
  rgm_sh = rgm + 2LL;
  Int128::Lsr(&tmp1, &tmp, rgm_sh);
  // Get least significant, guard and round bits
  //Int128::Shr(&L, &tmp, rgm_sh + expWidth);
  L.low = tmp.extract(rgm_sh + expWidth,1LL);
  L.high = 0LL;
  G.low = tmp.extract(rgm_sh + expWidth - 1LL, 1LL);
  //Int128::Shr(&G, &tmp, rgm_sh + expWidth - 1);
  //G.low &= 1LL;
  G.high = 0LL;
  Int128::Lsr(&R, &tmp, rgm_sh + expWidth - 2);
  R.low = tmp.extract(rgm_sh + expWidth - 2LL, 1LL);
  //R.low &= 1LL;
  R.high = 0LL;
  // Calc sticky bit
  S = tmp.StickyCalc(rgm_sh - 2 + expWidth);
  //for (nn = 0; nn < posWidth; nn++) {
  //  if (nn < rgm_sh - 2 + expWidth)
  //    S = S | ((tmp.low >> nn) & 1LL);
  //}
  Int128::Lsr(&tmp2, &tmp1, expWidth + 2LL);
  rnd_ulp = ((G.low & (R.low | S)) | (L.low & G.low & ~(R.low | S)));
  tmp3.low = rnd_ulp;
  tmp3.high = 0LL;
  Int128::Add(&tmp2_rnd, &tmp2, &tmp3);
  tmp2_rnd.low &= 0x7fffffff;
  if (i == 0)
    pst.val = 0;
  else if (i < 0)
    pst.val = -tmp2_rnd.low;
  else
    pst.val = tmp2_rnd.low;
  return (pst);
}

int64_t Posit32::PositToInt(Posit32 p)
{
  return (0);
}

void Posit32::Decompose(Posit32 a, RawPosit* b)
{
  uint64_t n;
  int8_t rgmlen;
  int8_t exp;
  int8_t sign;
  int64_t regexp;

  sign = (a.val >> posWidth-1LL) & 1LL;
  n = a.val < 0 ? -a.val : a.val;
  rgmlen = countLeadingBits(n << 1LL) + 1;
  regexp = (n >> (posWidth - rgmlen - expWidth - 1LL));
  exp = (n >> (posWidth - rgmlen - expWidth - 1LL)) & ((1 << expWidth) - 1);
  b->Size(expWidth, posWidth);
  b->isNaR = a.val == 0x80000000;
  b->isInf = a.val == 0x80000000;
  b->isZero = a.val == 0LL;
  b->sign = sign;
  b->exp = exp;
  b->regexp = regexp;
  b->regsign = (n >> (posWidth - 2LL)) & 1LL;
  b->regime = b->regsign ? rgmlen - 1: rgmlen;
  b->sigWidth = max(0, posWidth - rgmlen - expWidth);
  // Significand is left aligned.
  if (posWidth - rgmlen - expWidth - 1 >= 0) {
    n = n << rgmlen + expWidth; // Left align significand, + 1 for sign bit - 1 for hidden bit
    n = n >> expWidth;
    //n = n & ~(0xffffffffffffffffULL << (posWidth - 1LL - rgmlen - expWidth));
    if (!b->isZero)
      n = n | (1LL << (posWidth - expWidth - 1LL));
    b->sig.low = n;
    b->sig.high = 0LL;
  }
  else
    Int128::Assign(&b->sig, &Int128::Convert(0x40000000LL));
  if (b->isZero)
    b->sig = *Int128::Zero();
}

char* Posit32::ToString()
{
  static char buf[20];
  sprintf_s(buf, sizeof(buf), "%04X", val);
  return (buf);
}

Posit64 Posit32::ConvertTo64()
{
  RawPosit aa(2, 32);
  RawPosit bb(3, 64);
  Posit64 b;
  int64_t x;
  Int128 ai128;

  Decompose(*this, &aa);
  bb.isInf = aa.isInf;
  bb.isZero = aa.isZero;
  if (bb.isInf) {
    b.val = 0x8000000000000000LL;
    return (b);
  }
  if (bb.isZero) {
    b.val = 0LL;
    return (b);
  }
  int64_t rgma = (aa.regsign) ? aa.regime : -aa.regime;
  x = (rgma << aa.expWidth) + aa.exp;
  int64_t rgmb = (x >> bb.expWidth);
  bb.exp = x - (rgmb << bb.expWidth);
  bb.regime = aa.regsign ? rgmb : -rgmb;
  bb.regsign = aa.regsign;
  bb.regexp = (bb.regime << bb.expWidth) | bb.exp;
  int64_t r = bb.regsign ? 0LL : -1LL;
  ai128.insert((int64_t)aa.sig.low, 0, aa.sigWidth);
  ai128.insert(bb.exp, aa.sigWidth, bb.expWidth);
  ai128.insert(bb.regsign, aa.sigWidth + 1LL, 1);
  ai128.insert(r, aa.sigWidth + bb.expWidth + 1LL, 64LL);
  ai128.Shl(&ai128, &ai128, 64LL - aa.sigWidth);
  ai128.Lsr(&ai128, &ai128, rgmb + bb.expWidth);
  int64_t tmp1 = ai128.extract(rgmb + bb.expWidth, b.posWidth);
  int64_t abs_tmp = aa.sign ? -tmp1 : tmp1;
  b.val = (aa.sign << (b.posWidth - 1LL)) | ((uint64_t)abs_tmp >> 1LL);
  return (b);
}
