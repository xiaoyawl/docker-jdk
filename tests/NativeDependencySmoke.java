// 作者：Manta <manta.ops.dstw@gmail.com>
// 不预加载兼容库，验证LD_LIBRARY_PATH可解析JNI组件的传递依赖。
public class NativeDependencySmoke {
    private static native boolean testLegacy();

    public static void main(String[] args) {
        System.load(args[0]);
        if (!testLegacy()) {
            throw new IllegalStateException("OpenSSL兼容库加密及SSL上下文验证失败");
        }
        System.out.println("LD_LIBRARY_PATH传递依赖、SHA-256和SSL上下文验证通过");
    }
}
