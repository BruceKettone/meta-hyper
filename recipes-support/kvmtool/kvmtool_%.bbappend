FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://0001-disable-ipc.patch"

SRCREV = "f67bc0bdae9433a9cfd05e65ea2c1bb6102566d9"
PV = "2026.08+git${SRCPV}"
