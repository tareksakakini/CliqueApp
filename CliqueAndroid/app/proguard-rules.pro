# Keep Firebase models that rely on reflection
-keepclassmembers class com.clique.app.data.model.** { *; }
-keep class com.clique.app.data.model.** { *; }

# Keep Kotlin parcelables
-keepclassmembers class ** implements android.os.Parcelable {
    public static final ** CREATOR;
}
