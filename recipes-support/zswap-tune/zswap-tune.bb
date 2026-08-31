SUMMARY = "Memory tuning and ZSWAP setup for the host"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://zswap-tune.sh"
S = "${UNPACKDIR}"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${S}/zswap-tune.sh ${D}${bindir}/zswap-tune
}
