# Flutter rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# Speech to Text rules
-keep class com.csdcorp.speech_to_text.** { *; }

# Isar rules
-keep class io.isar.** { *; }
-keep class * extends io.isar.IsarLink { *; }
-keep class * extends io.isar.IsarCollection { *; }

# General rules to prevent stripping important classes
-dontwarn io.flutter.embedding.**
-dontwarn com.csdcorp.speech_to_text.**
-dontwarn io.isar.**
