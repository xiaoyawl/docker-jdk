#!/bin/sh
# 作者：Manta <manta.ops.dstw@gmail.com>
# 仅为JDK8/Alpine提供旧业务JNI所需的OpenSSL ABI，不替换系统OpenSSL。
set -eu

mkdir -p /compat-root
if [ "${JAVA_VERSION}" != 8 ] || ! command -v apk >/dev/null 2>&1; then
    exit 0
fi

version=1.0.0s
archive="openssl-${version}.tar.gz"
checksum=fb839f75b9b7195a0aaf307ca064b4358edb968a9524cbdf0a9e56d632f27a7b
prefix="/opt/compat/openssl-${version}"
apk add --no-cache build-base linux-headers perl curl ca-certificates
mkdir /tmp/openssl-build
cd /tmp/openssl-build
curl -fLsS --connect-timeout 20 --max-time 180 \
    --user-agent 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36' \
    -o "$archive" "https://github.com/openssl/openssl/releases/download/OpenSSL_1_0_0s/$archive"
printf '%s  %s\n' "$checksum" "$archive" | sha256sum -c -
tar -xzf "$archive"
cd "openssl-${version}"
# musl提供POSIX termios接口，不提供旧System V termio接口。
sed -i 's/-DTERMIO /-DTERMIOS /g' Configure
sed -i 's/defined(linux) \&\& !defined(TERMIO)/defined(linux) \&\& !defined(TERMIO) \&\& !defined(TERMIOS)/' crypto/ui/ui_openssl.c
# generic64禁用汇编，分别使用目标架构工具链，不采用宿主CPU特性。
perl ./Configure linux-generic64 shared no-asm -fcommon \
    --prefix="$prefix" --openssldir="$prefix/ssl"
make -j2 build_crypto
make -j2 build_ssl
make build_engines build_apps build_tests build_tools
# CMS固定证书于2016年过期；其余测试照常执行，单独核对CMS失败原因。
make test TESTS='test_des test_idea test_sha test_md4 test_md5 test_hmac test_md2 test_mdc2 test_wp test_rmd test_rc2 test_rc4 test_rc5 test_bf test_cast test_aes test_rand test_bn test_ec test_ecdsa test_ecdh test_enc test_x509 test_rsa test_crl test_sid test_gen test_req test_pkcs7 test_verify test_dh test_dsa test_ss test_ca test_engine test_evp test_ssl test_tsa test_ige test_jpake test_constant_time'
if (cd test && perl cms-test.pl); then
    printf 'CMS测试通过\n'
else
    cat test/cms.err
    grep -F 'certificate has expired' test/cms.err
    printf 'CMS固定测试证书已过期；该项不计为通过，其他测试已通过。\n'
fi
LD_LIBRARY_PATH="$PWD" ./apps/openssl version | grep -F 'OpenSSL 1.0.0s 11 Jun 2015'
mkdir -p "/compat-root$prefix/lib" "/compat-root$prefix/share" /compat-root/usr/local/lib
for library in libcrypto.so.1.0.0 libssl.so.1.0.0; do
    cp "$library" "/compat-root$prefix/lib/$library"
    ln -s "$prefix/lib/$library" "/compat-root/usr/local/lib/$library"
done
cp LICENSE "/compat-root$prefix/share/LICENSE"
printf '%s  %s\n' "$checksum" "$archive" > "/compat-root$prefix/share/SOURCE.sha256"
printf 'OpenSSL %s；仅供旧ABI兼容，已结束支持；系统OpenSSL保持独立。\n' "$version" \
    > "/compat-root$prefix/share/说明.txt"
