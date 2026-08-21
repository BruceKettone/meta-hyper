FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "${@'file://guest.cfg file://guest-kvm.cfg' if d.getVar('BB_CURRENT_MC') == 'guest' else ''}"

# Explicitly declare compatibility with our custom guest machine
COMPATIBLE_MACHINE:lkvm-arm64 = "lkvm-arm64"
