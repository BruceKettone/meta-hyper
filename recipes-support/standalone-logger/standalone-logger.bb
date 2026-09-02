SUMMARY = "Telemetry script to log standalone memory consumption"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://standalone-logger.sh"
S = "${UNPACKDIR}"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${S}/standalone-logger.sh ${D}${bindir}/standalone-logger
}
