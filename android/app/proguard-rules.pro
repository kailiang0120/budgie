# Keep rules for TensorFlow Lite to prevent R8 from stripping away essential classes.

# TensorFlow Lite Core
# This rule keeps all classes in the org.tensorflow.lite package, which is
# essential for the core functionality of the TFLite runtime.
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**

# TensorFlow Lite GPU Delegate
# The GpuDelegate classes are loaded via reflection, so R8 cannot detect their
# usage statically. This rule ensures they are not removed.
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.gpu.** 