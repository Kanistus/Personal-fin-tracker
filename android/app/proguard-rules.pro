# Flutter specific rules
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# Keep sqflite
-keep class com.tekartik.sqflite.** { *; }

# Keep share_plus
-keep class dev.fluttercommunity.plus.share.** { *; }

# Keep path_provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# General Android rules
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
