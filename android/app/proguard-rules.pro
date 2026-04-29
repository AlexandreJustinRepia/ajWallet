# Flutter rules — keep all Flutter engine classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-dontwarn io.flutter.embedding.**

# Hive — keep model adapters
-keep class com.rootexp.** { *; }
-keepattributes *Annotation*

# Keep Kotlin metadata
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**

# Keep Hive TypeAdapters
-keep class * extends com.google.flatbuffers.Table { *; }
-keep @interface dev.hive.annotations.*
