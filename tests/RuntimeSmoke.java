// 作者：Manta <manta.ops.dstw@gmail.com>
// 验证安全重建镜像的运行时版本、时区、加密和默认 HTTPS 信任。
import java.net.URL;
import java.security.MessageDigest;
import java.util.TimeZone;
import javax.net.ssl.HttpsURLConnection;

public class RuntimeSmoke {
    public static void main(String[] args) throws Exception {
        String expected = System.getenv("EXPECTED_RUNTIME");
        String actual = System.getProperty("java.runtime.version");
        if (!actual.equals(expected)) {
            throw new IllegalStateException("运行时版本不匹配：" + actual);
        }
        if (!"Asia/Shanghai".equals(TimeZone.getDefault().getID())) {
            throw new IllegalStateException("时区不符合预期");
        }
        MessageDigest.getInstance("SHA-256").digest(new byte[] {1, 2, 3});
        HttpsURLConnection connection = (HttpsURLConnection)
            new URL("https://mirrors.dtops.co/Java/").openConnection();
        connection.setConnectTimeout(30000);
        connection.setReadTimeout(30000);
        try {
            if (connection.getResponseCode() != 200) {
                throw new IllegalStateException("HTTPS 请求未返回 200");
            }
            System.out.println("运行时、时区、SHA-256 和 HTTPS 验证通过：" + actual);
        } finally {
            connection.disconnect();
        }
    }
}
