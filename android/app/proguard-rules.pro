# Notification receivers and callbacks can be entered by Android rather than
# directly from Dart code. Keep the plugin boundary while allowing the rest of
# the Java/Kotlin graph and Android resources to be optimized by R8.
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Preserve the generated Flutter plugin registration entry point.
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
