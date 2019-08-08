# AlpineLinux with a glibc-2.25-r1 and Oracle Java
FROM benyoo/alpine:3.9.20190527
MAINTAINER from www.dwhd.org by lookback (mondeolove@gmail.com)


# Java Version and other ENV
ARG JAVA_VERSION_MAJOR=${JAVA_VERSION_MAJOR:-8}
ARG JAVA_VERSION_MINOR=${JAVA_VERSION_MINOR:-221}
ARG JAVA_VERSION_BUILD=${JAVA_VERSION_BUILD:-11}
#ARG JAVA_JCE=${JAVA_JCE:-standard}
ARG JAVA_JCE=${JAVA_JCE:-unlimited}

ENV JAVA_PACKAGE=jdk \
	JAVA_HOME=/opt/jdk \
	PATH=${PATH}:/opt/jdk/bin \
	GLIBC_VERSION=2.29-r0 \
	LANG=zh_CN.UTF-8
#	LANG=C.UTF-8

# do all in one step
RUN set -ex && \
	[ ! -d ${JAVA_HOME} ] && mkdir -p ${JAVA_HOME} && \
	apk upgrade --update && apk add --update libstdc++ ca-certificates font-adobe-100dpi wget curl axel && \
#Install glibc
	glibc_url="https://github.com/sgerrand/alpine-pkg-glibc/releases/download/unreleased" && \
	for pkg in glibc-${GLIBC_VERSION} glibc-bin-${GLIBC_VERSION} glibc-i18n-${GLIBC_VERSION}; do curl -SLk ${glibc_url}/${pkg}.apk -o /tmp/${pkg}.apk; done && \
	apk add --allow-untrusted /tmp/*.apk && \
	rm -v /tmp/*.apk && \
#Config system lanage zh_CN.UTF-8
	#( /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 C.UTF-8 || true ) && \
	#echo "export LANG=C.UTF-8" > /etc/profile.d/locale.sh && \
	( /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 zh_CN.UTF-8 || true ) && \
	echo "export LANG=zh_CN.UTF-8" > /etc/profile.d/locale.sh && \
	/usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib && \
#Download JDK
	if [ "${JAVA_VERSION_MINOR}" == "121" ]; then HASH_SUM=e9e7ea248e2c4826b92b3f075a80e441; \
	elif [ "${JAVA_VERSION_MINOR}" == "131" ]; then HASH_SUM=d54c1d3a095b4ff2b6607d096fa80163; fi && \
#	mirrors.dtops.cc/java/7/jre-7u80-linux-x64.tar.gz
	if [ "${JAVA_VERSION_MAJOR}" == 8 ]; then JDK_URL="https://mirrors.dtops.cc/java/8/${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-b${JAVA_VERSION_BUILD}/${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz"; fi && \
	if [ "${JAVA_VERSION_MAJOR}" == 7 ]; then JDK_URL="https://mirrors.dtops.cc/java/7/${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz"; fi && \
	axel -an 30 ${JDK_URL} -o /tmp/${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz && \
	tar xf /tmp/${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz -C ${JAVA_HOME} --strip-components=1 && \
	rm -rf /tmp/${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz && \
	if [ "${JAVA_JCE}" == "unlimited" ]; then echo "Installing Unlimited JCE policy" >&2 && \
		#http://www.oracle.com/technetwork/java/javase/downloads/jce-7-download-432124.html
		#http://www.oracle.com/technetwork/java/javase/downloads/jce8-download-2133166.html
		if [ "${JAVA_VERSION_MAJOR}" == 7 ]; then JCEPolicyJDKURL="http://download.oracle.com/otn-pub/java/jce/${JAVA_VERSION_MAJOR}/UnlimitedJCEPolicyJDK${JAVA_VERSION_MAJOR}.zip"; fi && \
		if [ "${JAVA_VERSION_MAJOR}" == 8 ]; then JCEPolicyJDKURL="http://download.oracle.com/otn-pub/java/jce/${JAVA_VERSION_MAJOR}/jce_policy-${JAVA_VERSION_MAJOR}.zip"; fi && \
		curl -Lk -C - -b "oraclelicense=accept-securebackup-cookie" ${JCEPolicyJDKURL} >/tmp/jce_policy-${JAVA_VERSION_MAJOR}.zip && \
		cd /tmp && unzip /tmp/jce_policy-${JAVA_VERSION_MAJOR}.zip && cd - && \
		mv /tmp/UnlimitedJCE* /tmp/UnlimitedJCEPolicyJDK && \
		cp -v /tmp/UnlimitedJCEPolicyJDK/*.jar /opt/jdk/jre/lib/security; \
	fi && \
	sed -i s/#networkaddress.cache.ttl=-1/networkaddress.cache.ttl=10/ $JAVA_HOME/jre/lib/security/java.security && \
	apk del curl glibc-i18n && \
	rm -rf /opt/jdk/*src.zip \
		/opt/jdk/lib/missioncontrol \
		/opt/jdk/lib/visualvm \
		/opt/jdk/lib/*javafx* \
		/opt/jdk/jre/plugin \
		/opt/jdk/jre/bin/javaws \
		/opt/jdk/jre/bin/jjs \
		/opt/jdk/jre/bin/orbd \
		/opt/jdk/jre/bin/pack200 \
		/opt/jdk/jre/bin/policytool \
		/opt/jdk/jre/bin/rmid \
		/opt/jdk/jre/bin/rmiregistry \
		/opt/jdk/jre/bin/servertool \
		/opt/jdk/jre/bin/tnameserv \
		/opt/jdk/jre/bin/unpack200 \
		/opt/jdk/jre/lib/javaws.jar \
		/opt/jdk/jre/lib/deploy* \
		/opt/jdk/jre/lib/desktop \
		/opt/jdk/jre/lib/*javafx* \
		/opt/jdk/jre/lib/*jfx* \
		/opt/jdk/jre/lib/amd64/libdecora_sse.so \
		/opt/jdk/jre/lib/amd64/libprism_*.so \
		/opt/jdk/jre/lib/amd64/libfxplugins.so \
		/opt/jdk/jre/lib/amd64/libglass.so \
		/opt/jdk/jre/lib/amd64/libgstreamer-lite.so \
		/opt/jdk/jre/lib/amd64/libjavafx*.so \
		/opt/jdk/jre/lib/amd64/libjfx*.so \
		/opt/jdk/jre/lib/ext/jfxrt.jar \
		/opt/jdk/jre/lib/ext/nashorn.jar \
		/opt/jdk/jre/lib/oblique-fonts \
		/opt/jdk/jre/lib/plugin.jar \
		/tmp/* /var/cache/apk/* && \
	echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf
