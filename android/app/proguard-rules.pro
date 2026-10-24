# google_mlkit_text_recognition references the optional non-Latin script
# recognizers (chinese/devanagari/japanese/korean) that it declares as
# compileOnly, so R8 sees missing classes in release builds. FCBaz only uses
# TextRecognitionScript.latin, so those references are never executed.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# firebase-components' own consumer rule keeps ComponentRegistrar classes but
# not their members. R8 full mode (default on AGP 9) then strips the no-arg
# constructor, so ML Kit cannot build its registry, MlKitContext stays null and
# TextRecognition.getClient() crashes with a NullPointerException in release.
-keep class * implements com.google.firebase.components.ComponentRegistrar {
    *;
}
