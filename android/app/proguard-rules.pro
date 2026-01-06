# ProGuard rules for SLAPP

# Keep Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Supabase
-keep class io.supabase.** { *; }

# Keep Google Fonts
-keep class com.google.** { *; }

# Speech to text
-keep class com.csdcorp.speech_to_text.** { *; }

# General Android rules
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Kotlin
-dontwarn kotlin.**
-keep class kotlin.** { *; }
