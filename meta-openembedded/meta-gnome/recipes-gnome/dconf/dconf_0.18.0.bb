SUMMARY = "configuation database system"
LICENSE = "LGPLv2.1"
LIC_FILES_CHKSUM = "file://COPYING;md5=2d5025d4aa3495befef8f17206a5b0a1"

SECTION = "x11/gnome"

inherit gnomebase gsettings
SRC_URI[archive.md5sum] = "69a12ed68893f2e1e81ac4e531bc1515"
SRC_URI[archive.sha256sum] = "109b1bc6078690af1ed88cb144ef5c5aee7304769d8bdc82ed48c3696f10c955"
GNOME_COMPRESS_TYPE = "xz"

DEPENDS = "dbus glib-2.0 gtk+3 libxml2 intltool-native"

inherit vala gtk-doc distro_features_check

REQUIRED_DISTRO_FEATURES = "x11"

EXTRA_OECONF += "--disable-man"

PACKAGES =+ "dconf-editor"

FILES_${PN} += " \
    ${datadir}/dbus-1 \
    ${libdir}/gio/modules/*.so \
"
FILES_dconf-editor = " \
    ${bindir}/dconf-editor \
    ${datadir}/icons \
    ${datadir}/bash-completion \
"
FILES_${PN}-dbg += "${libdir}/gio/modules/.debug/libdconfsettings.so"
