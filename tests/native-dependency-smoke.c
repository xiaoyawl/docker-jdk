/* 作者：Manta <manta.ops.dstw@gmail.com>；通用JNI依赖测试，不包含业务代码。 */
#include <jni.h>
#include <openssl/ssl.h>
#include <openssl/sha.h>
#include <string.h>

JNIEXPORT jboolean JNICALL Java_NativeDependencySmoke_testLegacy(JNIEnv *env, jclass type)
{
    static const unsigned char expected[32] = {
        0xba, 0x78, 0x16, 0xbf, 0x8f, 0x01, 0xcf, 0xea,
        0x41, 0x41, 0x40, 0xde, 0x5d, 0xae, 0x22, 0x23,
        0xb0, 0x03, 0x61, 0xa3, 0x96, 0x17, 0x7a, 0x9c,
        0xb4, 0x10, 0xff, 0x61, 0xf2, 0x00, 0x15, 0xad
    };
    unsigned char actual[32];
    SSL_CTX *context;
    (void)env;
    (void)type;
    if (strncmp(SSLeay_version(SSLEAY_VERSION), "OpenSSL 1.0.0s ", 15) != 0) {
        return JNI_FALSE;
    }
    SHA256((const unsigned char *)"abc", 3, actual);
    if (memcmp(actual, expected, sizeof(expected)) != 0 || SSL_library_init() != 1) {
        return JNI_FALSE;
    }
    context = SSL_CTX_new(SSLv23_method());
    if (context == NULL) {
        return JNI_FALSE;
    }
    SSL_CTX_free(context);
    return JNI_TRUE;
}
