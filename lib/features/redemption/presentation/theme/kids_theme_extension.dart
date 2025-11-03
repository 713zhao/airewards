import 'package:flutter/material.dart';

/// Kids-friendly theme extension for redemption feature
/// 
/// This extension provides bright, fun colors and playful styles
/// specifically designed for children's engagement and accessibility.
class KidsThemeExtension extends ThemeExtension<KidsThemeExtension> {
  const KidsThemeExtension({
    required this.primaryFun,
    required this.secondaryFun,
    required this.successFun,
    required this.warningFun,
    required this.errorFun,
    required this.backgroundFun,
    required this.surfaceFun,
    required this.cardFun,
    required this.coinGold,
    required this.coinSilver,
    required this.coinBronze,
    required this.starYellow,
    required this.heartRed,
    required this.leafGreen,
    required this.skyBlue,
    required this.sunOrange,
    required this.purpleMagic,
    required this.pinkBubble,
  });

  /// Bright, engaging primary color (Happy Blue)
  final Color primaryFun;
  
  /// Cheerful secondary color (Sunshine Yellow)
  final Color secondaryFun;
  
  /// Success/reward color (Victory Green)
  final Color successFun;
  
  /// Warning/attention color (Friendly Orange)
  final Color warningFun;
  
  /// Error color (Gentle Red)
  final Color errorFun;
  
  /// Background color (Soft Clouds)
  final Color backgroundFun;
  
  /// Surface color (Clean White)
  final Color surfaceFun;
  
  /// Card background (Pastel Blue)
  final Color cardFun;
  
  /// Coin colors for points display
  final Color coinGold;
  final Color coinSilver;
  final Color coinBronze;
  
  /// Fun accent colors
  final Color starYellow;
  final Color heartRed;
  final Color leafGreen;
  final Color skyBlue;
  final Color sunOrange;
  final Color purpleMagic;
  final Color pinkBubble;

  /// Light theme kids colors
  static const KidsThemeExtension light = KidsThemeExtension(
    primaryFun: Color(0xFF2196F3),     // Bright Blue
    secondaryFun: Color(0xFFFFC107),   // Sunshine Yellow
    successFun: Color(0xFF4CAF50),     // Happy Green
    warningFun: Color(0xFFFF9800),     // Friendly Orange
    errorFun: Color(0xFFE57373),       // Gentle Red
    backgroundFun: Color(0xFFF8F9FF),  // Soft Blue White
    surfaceFun: Color(0xFFFFFFFF),     // Pure White
    cardFun: Color(0xFFE3F2FD),        // Light Blue
    coinGold: Color(0xFFFFD700),       // Gold
    coinSilver: Color(0xFFC0C0C0),     // Silver
    coinBronze: Color(0xFFCD7F32),     // Bronze
    starYellow: Color(0xFFFFF176),     // Bright Yellow Star
    heartRed: Color(0xFFFF5722),       // Warm Red Heart
    leafGreen: Color(0xFF8BC34A),      // Fresh Green Leaf
    skyBlue: Color(0xFF87CEEB),        // Sky Blue
    sunOrange: Color(0xFFFFB74D),      // Warm Sun Orange
    purpleMagic: Color(0xFF9C27B0),    // Magic Purple
    pinkBubble: Color(0xFFE91E63),     // Bubble Pink
  );

  /// Dark theme kids colors (softer for evening use)
  static const KidsThemeExtension dark = KidsThemeExtension(
    primaryFun: Color(0xFF64B5F6),     // Softer Blue
    secondaryFun: Color(0xFFFFEB3B),   // Gentle Yellow
    successFun: Color(0xFF81C784),     // Calm Green
    warningFun: Color(0xFFFFB74D),     // Warm Orange
    errorFun: Color(0xFFEF5350),       // Soft Red
    backgroundFun: Color(0xFF121212),  // Dark Background
    surfaceFun: Color(0xFF1E1E1E),     // Dark Surface
    cardFun: Color(0xFF2C2C2C),        // Dark Card
    coinGold: Color(0xFFFFD54F),       // Softer Gold
    coinSilver: Color(0xFFBDBDBD),     // Muted Silver
    coinBronze: Color(0xFFBCAAA4),     // Soft Bronze
    starYellow: Color(0xFFFFF59D),     // Gentle Star
    heartRed: Color(0xFFFF7043),       // Soft Heart
    leafGreen: Color(0xFFAED581),      // Gentle Leaf
    skyBlue: Color(0xFF90CAF9),        // Night Sky
    sunOrange: Color(0xFFFFCC02),      // Moonlight Orange
    purpleMagic: Color(0xFFBA68C8),    // Soft Magic
    pinkBubble: Color(0xFFF06292),     // Gentle Pink
  );

  @override
  KidsThemeExtension copyWith({
    Color? primaryFun,
    Color? secondaryFun,
    Color? successFun,
    Color? warningFun,
    Color? errorFun,
    Color? backgroundFun,
    Color? surfaceFun,
    Color? cardFun,
    Color? coinGold,
    Color? coinSilver,
    Color? coinBronze,
    Color? starYellow,
    Color? heartRed,
    Color? leafGreen,
    Color? skyBlue,
    Color? sunOrange,
    Color? purpleMagic,
    Color? pinkBubble,
  }) {
    return KidsThemeExtension(
      primaryFun: primaryFun ?? this.primaryFun,
      secondaryFun: secondaryFun ?? this.secondaryFun,
      successFun: successFun ?? this.successFun,
      warningFun: warningFun ?? this.warningFun,
      errorFun: errorFun ?? this.errorFun,
      backgroundFun: backgroundFun ?? this.backgroundFun,
      surfaceFun: surfaceFun ?? this.surfaceFun,
      cardFun: cardFun ?? this.cardFun,
      coinGold: coinGold ?? this.coinGold,
      coinSilver: coinSilver ?? this.coinSilver,
      coinBronze: coinBronze ?? this.coinBronze,
      starYellow: starYellow ?? this.starYellow,
      heartRed: heartRed ?? this.heartRed,
      leafGreen: leafGreen ?? this.leafGreen,
      skyBlue: skyBlue ?? this.skyBlue,
      sunOrange: sunOrange ?? this.sunOrange,
      purpleMagic: purpleMagic ?? this.purpleMagic,
      pinkBubble: pinkBubble ?? this.pinkBubble,
    );
  }

  @override
  KidsThemeExtension lerp(KidsThemeExtension? other, double t) {
    if (other is! KidsThemeExtension) return this;
    
    return KidsThemeExtension(
      primaryFun: Color.lerp(primaryFun, other.primaryFun, t)!,
      secondaryFun: Color.lerp(secondaryFun, other.secondaryFun, t)!,
      successFun: Color.lerp(successFun, other.successFun, t)!,
      warningFun: Color.lerp(warningFun, other.warningFun, t)!,
      errorFun: Color.lerp(errorFun, other.errorFun, t)!,
      backgroundFun: Color.lerp(backgroundFun, other.backgroundFun, t)!,
      surfaceFun: Color.lerp(surfaceFun, other.surfaceFun, t)!,
      cardFun: Color.lerp(cardFun, other.cardFun, t)!,
      coinGold: Color.lerp(coinGold, other.coinGold, t)!,
      coinSilver: Color.lerp(coinSilver, other.coinSilver, t)!,
      coinBronze: Color.lerp(coinBronze, other.coinBronze, t)!,
      starYellow: Color.lerp(starYellow, other.starYellow, t)!,
      heartRed: Color.lerp(heartRed, other.heartRed, t)!,
      leafGreen: Color.lerp(leafGreen, other.leafGreen, t)!,
      skyBlue: Color.lerp(skyBlue, other.skyBlue, t)!,
      sunOrange: Color.lerp(sunOrange, other.sunOrange, t)!,
      purpleMagic: Color.lerp(purpleMagic, other.purpleMagic, t)!,
      pinkBubble: Color.lerp(pinkBubble, other.pinkBubble, t)!,
    );
  }
}

/// Extension to easily access kids theme from BuildContext
extension KidsThemeContext on BuildContext {
  KidsThemeExtension get kidsTheme {
    return Theme.of(this).extension<KidsThemeExtension>() ?? KidsThemeExtension.light;
  }
}