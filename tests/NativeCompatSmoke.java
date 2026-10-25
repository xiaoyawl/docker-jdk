import java.io.File;

/** 验证镜像内的旧ABI库可加载；不包含业务JNI组件。 */
public class NativeCompatSmoke {
    public static void main(String[] args) {
        String directory = "/opt/compat/openssl-1.0.0s/lib/";
        for (String name : new String[]{"libcrypto.so.1.0.0", "libssl.so.1.0.0"}) {
            File library = new File(directory + name);
            if (!library.isFile()) {
                throw new IllegalStateException("缺少兼容库：" + library);
            }
            System.load(library.getAbsolutePath());
            System.out.println("兼容库加载通过：" + name);
        }
    }
}
