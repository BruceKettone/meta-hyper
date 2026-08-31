SUMMARY = "Hypervisor Host Image (Base)"
IMAGE_INSTALL = "packagegroup-core-boot kernel-image"
IMAGE_LINGUAS = "en-us"
LICENSE = "MIT"
inherit core-image
IMAGE_FSTYPES = "erofs"
IMAGE_ROOTFS_SIZE ?= "8192"
IMAGE_ROOTFS_EXTRA_SPACE:append = "${@bb.utils.contains("DISTRO_FEATURES", "systemd", " + 4096", "", d)}"

do_rootfs[mcdepends] += "mc:${BB_CURRENT_MC}:guest:kvmtool-guest-image:do_image_complete"

def get_guest_machine(d):
    import re
    from pathlib import Path
    
    for p in d.getVar('BBPATH').split(':'):
        conf_path = Path(p) / 'conf' / 'multiconfig' / 'guest.conf'
        if conf_path.exists():
            with conf_path.open('r') as f:
                for line in f:
                    m = re.match(r'^MACHINE\s*=\s*"([^"]+)"', line)
                    if m:
                        return m.group(1)
    return "lkvm-arm64"

# The host's TMPDIR is already suffixed (e.g. tmp-host-zswap), so we use /.. to traverse back to the base tmp-guest directory
GUEST_DEPLOY_DIR = "${TMPDIR}/../tmp-guest/deploy/images/${@get_guest_machine(d)}"

inject_guest_kernel() {
    # No existence check needed; mcdepends guarantees the file is compiled and present
    install -m 0644 "${GUEST_DEPLOY_DIR}/Image" "${IMAGE_ROOTFS}/guest-Image"
}
ROOTFS_POSTPROCESS_COMMAND += "inject_guest_kernel; "
