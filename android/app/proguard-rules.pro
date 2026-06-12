# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ML Kit – optionale Sprachmodelle werden nicht verwendet (nur Latein)
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Flutter Play Store Deferred Components – nicht genutzt (kein Dynamic Delivery)
-dontwarn com.google.android.play.core.**
