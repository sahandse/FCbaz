# google_mlkit_text_recognition references the optional non-Latin script
# recognizers (chinese/devanagari/japanese/korean) that it declares as
# compileOnly, so R8 sees missing classes in release builds. FCBaz only uses
# TextRecognitionScript.latin, so those references are never executed.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
