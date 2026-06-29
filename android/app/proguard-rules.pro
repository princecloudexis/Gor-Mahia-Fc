# This file contains the rules for R8/ProGuard for a release build.

# Flutter-specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Stripe SDK rules
-keepclassmembers class com.stripe.android.** {
    @com.google.gson.annotations.SerializedName <fields>;
}
-keep class org.bouncycastle.** { *; }
-keep class kotlinx.serialization.** { *; }

# --- THESE ARE THE RULES THAT FIX YOUR BUILD ERROR ---

# Rule for Flutter's deferred components (Play Store Split Install)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Rule for Stripe's optional Push Provisioning feature
-dontwarn com.stripe.android.pushProvisioning.**
-keep class com.stripe.android.pushProvisioning.** { *; }

# Rule to ignore the unexpected React Native Stripe SDK classes.
-dontwarn com.reactnativestripesdk.**

# General rules for Google Pay / Wallet
-dontwarn com.google.android.gms.wallet.**
-dontwarn com.google.android.gms.tasks.**
-dontwarn com.google.android.material.bottomsheet.**

# Razorpay SDK rules
-keepattributes *Annotation*
-dontwarn com.razorpay.**
-keep class com.razorpay.** {*;}
-optimizations !method/inlining/
-keepclasseswithmembers class * {
    public void onPayment*(...);
}
