SUMMARY = "Helper script to launch the nested lkvm guest"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://launch-guest.sh"

S = "${UNPACKDIR}"

do_install() {
    # Create the /usr/bin directory in the rootfs
    install -d ${D}${bindir}
    
    # Install the script with executable permissions
    install -m 0755 ${S}/launch-guest.sh ${D}${bindir}/launch-guest
}
