// 作者：Manta <manta.ops.dstw@gmail.com>
// 验证中英文字形、离屏绘图、图片编解码与 AWT 的 X11 本地库依赖。
import java.awt.Color;
import java.awt.Font;
import java.awt.Graphics2D;
import java.awt.GraphicsEnvironment;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import javax.imageio.ImageIO;

public class GraphicsSmoke {
    public static void main(String[] args) throws Exception {
        if (args.length > 0 && "--load-awt".equals(args[0])) {
            String home = System.getProperty("java.home");
            String[] paths = {"/lib/libawt_xawt.so", "/lib/amd64/libawt_xawt.so",
                "/lib/aarch64/libawt_xawt.so"};
            for (String path : paths) {
                File library = new File(home + path);
                if (library.isFile()) {
                    System.load(library.getAbsolutePath());
                    System.out.println("AWT X11 本地库加载通过");
                    return;
                }
            }
            throw new IllegalStateException("缺少 AWT X11 本地库");
        }
        String text = "Hello 123 中文验证码图表";
        String[] families = GraphicsEnvironment.getLocalGraphicsEnvironment()
            .getAvailableFontFamilyNames();
        if (families.length == 0) {
            throw new IllegalStateException("未发现字体");
        }
        Font font = new Font("SansSerif", Font.PLAIN, 28);
        if (font.canDisplayUpTo(text) != -1) {
            throw new IllegalStateException("默认 SansSerif 缺少中英文字形");
        }
        BufferedImage image = new BufferedImage(640, 120, BufferedImage.TYPE_INT_RGB);
        Graphics2D graphics = image.createGraphics();
        try {
            graphics.setColor(Color.WHITE);
            graphics.fillRect(0, 0, image.getWidth(), image.getHeight());
            graphics.setColor(Color.BLACK);
            graphics.setFont(font);
            graphics.drawString(text, 16, 64);
        } finally {
            graphics.dispose();
        }
        int nonWhite = 0;
        for (int y = 0; y < image.getHeight(); y++) {
            for (int x = 0; x < image.getWidth(); x++) {
                if ((image.getRGB(x, y) & 0xffffff) != 0xffffff) nonWhite++;
            }
        }
        if (nonWhite < 100) throw new IllegalStateException("图片未绘出文字");
        for (String format : new String[] {"png", "jpeg", "gif"}) {
            ByteArrayOutputStream bytes = new ByteArrayOutputStream();
            if (!ImageIO.write(image, format, bytes)) {
                throw new IllegalStateException("缺少图片编码器：" + format);
            }
            BufferedImage decoded = ImageIO.read(new ByteArrayInputStream(bytes.toByteArray()));
            if (decoded == null || decoded.getWidth() != 640 || decoded.getHeight() != 120) {
                throw new IllegalStateException("图片解码失败：" + format);
            }
        }
        if (args.length > 0) ImageIO.write(image, "png", new File(args[0]));
        System.out.println("字体、中英文绘图、PNG/JPEG/GIF 编解码通过；字体家族数=" + families.length);
    }
}
