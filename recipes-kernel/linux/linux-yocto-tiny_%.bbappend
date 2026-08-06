FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "${@'file://host.cfg' if d.getVar('BB_CURRENT_MC') == 'host' else ''}"
SRC_URI += "${@'file://guest.cfg' if d.getVar('BB_CURRENT_MC') == 'guest' else ''}"
