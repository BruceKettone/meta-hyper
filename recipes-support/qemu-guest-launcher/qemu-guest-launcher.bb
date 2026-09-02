SUMMARY = "Helper script to launch the nested QEMU guest"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://launch-guest.sh"

S = "${UNPACKDIR}"

RDEPENDS:${PN} += "qemu"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${S}/launch-guest.sh ${D}${bindir}/launch-guest
}
