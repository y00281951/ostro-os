SRCREV = "3161bfa479d5e9ed4f46b57df9bcecbbc4f8eb3c"
PE = "1"
PV = "144.0+git${SRCPV}"

PACKAGES =+ "${PN}-iwlwifi-7260-10 ${PN}-iwlwifi-7260-12"

RDEPENDS_${PN}-iwlwifi-7260-10    = "${PN}-iwlwifi-license"
RDEPENDS_${PN}-iwlwifi-7260-12    = "${PN}-iwlwifi-license"

FILES_${PN}-iwlwifi-7260-10 = "/lib/firmware/iwlwifi-7260-10.ucode"
FILES_${PN}-iwlwifi-7260-12 = "/lib/firmware/iwlwifi-7260-12.ucode"
