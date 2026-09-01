require guest-image.inc
SUMMARY = "Guest Image - ZRAM"
IMAGE_INSTALL:append = " util-linux-zramctl zram-tune"
