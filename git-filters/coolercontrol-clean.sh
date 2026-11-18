#!/usr/bin/env bash
# git "clean" filtresi: CoolerControl.conf repoya girerken makineye ozel
# ve gizli kisimlari ayiklar. Diskteki dosyaya dokunmaz.
#   [daemonAccessTokens] / [daemonAccessTokenIds] -> daemon erisim token'i (gizli)
#   [daemonConnections]                           -> yerel daemon baglantisi
#   networkCookies=                               -> daemon oturum cerezi (gizli)
#   windowGeometry=                               -> pencere boyutu (ekrana ozel)
# Yeni makinede arayuz daemon'a ilk giriste token'i kendisi uretir.
# Kayit: bootstrap.sh -> git config filter.coolercontrol.clean
awk '
/^\[/ { skip = ($0 ~ /^\[(daemonAccessTokens|daemonAccessTokenIds|daemonConnections)\]$/) }
skip { next }
/^(networkCookies|windowGeometry)=/ { next }
/^$/ { blank++; next }
{ while (blank > 0) { print ""; blank-- } print }
'
