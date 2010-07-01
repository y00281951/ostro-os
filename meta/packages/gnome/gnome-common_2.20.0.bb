DESCRIPTION = "Common macros for building GNOME applications"
HOMEPAGE = "http://www.gnome.org/"
BUGTRACKER = "https://bugzilla.gnome.org/"

LICENSE = "GPLv3"

SECTION = "x11/gnome"
PR = "r1"
inherit gnome

# all isn't appropriate since STAGING_DATADIR is target specific
# PACKAGE_ARCH="all"

# The omf.make file failed if scrollkeeper doesn't happen to be
# installed

SRC_URI += "file://omf.patch;patch=1"

EXTRA_AUTORECONF = ""
DEPENDS = ""

FILES_${PN} += "${datadir}/aclocal"
FILES_${PN}-dev = ""
