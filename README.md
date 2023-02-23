# openbouffalo_dev_container
Since the instructions to build https://github.com/openbouffalo/buildroot_bouffalo didn't work in my gentoo, I created this ubuntu-based container image (as used in the https://github.com/openbouffalo/buildroot_bouffalo actions for building the official firmware binaries) of the environment ready for development, with all precompiled as in the official repo. Added ncurses to allow ```make menuconfig``` of the kernel.
## More BL808 info
 - https://wiki.pine64.org/wiki/Ox64
 - https://files.pine64.org/doc/ox64/PINE64_Ox64-Schematic-202221018.pdf
 - https://files.pine64.org/doc/datasheet/ox64/BL808_DS_en_1.1(open).pdf
 - https://raw.githubusercontent.com/bouffalolab/bl_docs/main/BL808_RM/en/BL808_RM_en_1.2.pdf
 - https://btashton.github.io/bl808-notes/index.html
 - https://twitter.com/btashton
 - https://github.com/bouffalolab/bl-pac
