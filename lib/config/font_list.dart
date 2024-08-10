List<String> fontNameList = [
  "OppoSans",
  "HanaMin",
  "AllertaStencil",
  "CabinSketch",
  "Foldit",
  "Glegoo",
  "KellySlab",
  "LXGWWenKai",
  "LXGWWenKaiMono",
  "Melete",
  "Monoton",
  "Unifont",
  "UnifontJP",
  "LXGWBright",
  "FusionPixelJa",
  "FusionPixelKo",
  "FusionPixelLatin",
  "FusionPixelZhHant",
  "FusionPixelZhHans",
  "SmileySans",
];

class FontFamilyName {
  static const String oppoSans = "OppoSans";
  static const String hanaMin = "HanaMin";
  static const String allertaStencil = "AllertaStencil";
  static const String cabinSketch = "CabinSketch";
  static const String foldit = "Foldit";
  static const String glegoo = "Glegoo";
  static const String kellySlab = "KellySlab";
  static const String lXGWWenKai = "LXGWWenKai";
  static const String lXGWWenKaiMono = "LXGWWenKaiMono";
  static const String melete = "Melete";
  static const String monoton = "Monoton";
  static const String unifont = "Unifont";
  static const String unifontJP = "UnifontJP";
  static const String lXGWBright = "LXGWBright";
  static const String fusionPixelJa = "FusionPixelJa";
  static const String fusionPixelKo = "FusionPixelKo";
  static const String fusionPixelLatin = "FusionPixelLatin";
  static const String fusionPixelZhHant = "FusionPixelZhHant";
  static const String fusionPixelZhHans = "FusionPixelZhHans";
  static const String smileySans = "SmileySans";

  getFontFamily(FontFamilyType fontFamilyType) {
    switch (fontFamilyType) {
      case FontFamilyType.oppoSans:
        return oppoSans;
      case FontFamilyType.hanaMin:
        return hanaMin;
      case FontFamilyType.allertaStencil:
        return allertaStencil;
      case FontFamilyType.cabinSketch:
        return cabinSketch;
      case FontFamilyType.foldit:
        return foldit;
      case FontFamilyType.glegoo:
        return glegoo;
      case FontFamilyType.kellySlab:
        return kellySlab;
      case FontFamilyType.lXGWWenKai:
        return lXGWWenKai;
      case FontFamilyType.lXGWWenKaiMono:
        return lXGWWenKaiMono;
      case FontFamilyType.melete:
        return melete;
      case FontFamilyType.monoton:
        return monoton;
      case FontFamilyType.unifont:
        return unifont;
      case FontFamilyType.unifontJP:
        return unifontJP;
      case FontFamilyType.lXGWBright:
        return lXGWBright;
      case FontFamilyType.fusionPixelJa:
        return fusionPixelJa;
      case FontFamilyType.fusionPixelKo:
        return fusionPixelKo;
      case FontFamilyType.fusionPixelLatin:
        return fusionPixelLatin;
      case FontFamilyType.fusionPixelZhHant:
        return fusionPixelZhHant;
      case FontFamilyType.fusionPixelZhHans:
        return fusionPixelZhHans;
      case FontFamilyType.smileySans:
        return smileySans;
      default:
        return oppoSans;
    }
  }
}

enum FontFamilyType {
  oppoSans,
  hanaMin,
  allertaStencil,
  cabinSketch,
  foldit,
  glegoo,
  kellySlab,
  lXGWWenKai,
  lXGWWenKaiMono,
  melete,
  monoton,
  unifont,
  unifontJP,
  lXGWBright,
  fusionPixelJa,
  fusionPixelKo,
  fusionPixelLatin,
  fusionPixelZhHant,
  fusionPixelZhHans,
  smileySans,
}
