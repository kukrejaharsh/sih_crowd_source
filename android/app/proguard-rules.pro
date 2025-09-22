# Flutter's default rules.
#
# See https://flutter.dev/docs/deployment/android#reviewing-the-build-configuration.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# This rule fixes the TensorFlow Lite build error.
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options

# THIS IS THE NEW RULE THAT FIXES YOUR CURRENT ERROR.
-dontwarn com.google.android.play.core.**

