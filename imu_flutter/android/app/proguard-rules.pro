# IMU Flutter App - ProGuard Rules for Release Builds
# Add project specific ProGuard rules here.

## Flutter rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

## PowerSync rules
-keep class com.powersync.** { *; }
-dontwarn com.powersync.**

## Riverpod rules
-keep class androidx.compose.** { *; }
-dontwarn androidx.compose.**

## Hive rules
-keep class com.hivedb.** { *; }
-dontwarn com.hivedb.**

## Mapbox rules
-keep class com.mapbox.mapboxsdk.** { *; }
-dontwarn com.mapbox.mapboxsdk.**

## Geolocator rules
-keep class com.baseflow.geolocator.** { *; }
-dontwarn com.baseflow.geolocator.**

## Image Picker rules
-keep class io.flutter.plugins.imagepicker.** { *; }
-dontwarn io.flutter.plugins.imagepicker.**

## Local Auth rules
-keep class io.flutter.plugins.localauth.** { *; }
-dontwarn io.flutter.plugins.localauth.**

## Secure Storage rules
-keep class com.it_nomads.flutter_secure_storage.** { *; }
-dontwarn com.it_nomads.flutter_secure_storage.**

## Connectivity rules
-keep class dev.fluttercommunity.plus.connectivity.** { *; }
-dontwarn dev.fluttercommunity.plus.connectivity.**

## Permission Handler rules
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

## Dio rules
-keep class dio3.** { *; }
-dontwarn dio3.**

## JSON serialization rules
-keepattributes *Implementation*
-keepclassmembers class * {
    public <methods>;
}

## Prevent obfuscation of model classes
-keep class imu.cfbtools.app.** { *; }
-keep class **_Model { *; }
-keep class **_Provider { *; }

## Preserve line numbers for debugging
-keepattributes SourceFile,LineNumberTable

## Google Play Core rules (for Play Store feature delivery)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

## Optimize
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-dontpreverify
-verbose
