FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "${@'file://guest.cfg file://guest-kvm.cfg' if (d.getVar('BB_CURRENT_MC') or '').startswith('guest') else ''}"
SRC_URI += "${@ 'file://' + d.getVar('HOST_SWAP_FEATURE') if d.getVar('HOST_SWAP_FEATURE') else '' }"

# Explicitly declare compatibility with our custom guest machine
COMPATIBLE_MACHINE:lkvm-arm64 = "lkvm-arm64"
