#!/bin/zsh
# Aggancia CCNotify.m (notifiche locali iOS) al progetto Xcode esportato da Godot.
# Uso: patch_notifications.sh <project.pbxproj> <dir_sorgenti_CubeCrash> <path_CCNotify.m>
set -e
PBX="$1"; DST="$2"; SRC="$3"
cp "$SRC" "$DST/CCNotify.m"
if grep -q "CCNotify.m" "$PBX"; then
	echo "CCNotify già presente nel pbxproj"; exit 0
fi
BF="CC0DA1100000000000000001"   # PBXBuildFile id
FR="CC0DA1100000000000000002"   # PBXFileReference id
# 1) PBXBuildFile (dopo la voce di dummy.cpp)
perl -i -pe '$_ .= "\t\t'"$BF"' /* CCNotify.m in Sources */ = {isa = PBXBuildFile; fileRef = '"$FR"' /* CCNotify.m */; };\n" if /dummy\.cpp in Sources \*\/ = \{isa = PBXBuildFile/;' "$PBX"
# 2) PBXFileReference
perl -i -pe '$_ .= "\t\t'"$FR"' /* CCNotify.m */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.c.objc; path = CCNotify.m; sourceTree = \"<group>\"; };\n" if /dummy\.cpp \*\/ = \{isa = PBXFileReference/;' "$PBX"
# 3) voce nel gruppo file
perl -i -pe '$_ .= "\t\t\t\t'"$FR"' /* CCNotify.m */,\n" if /dummy\.cpp \*\/,\s*$/;' "$PBX"
# 4) voce nella fase Sources (compilazione)
perl -i -pe '$_ .= "\t\t\t\t'"$BF"' /* CCNotify.m in Sources */,\n" if /dummy\.cpp in Sources \*\/,\s*$/;' "$PBX"
echo "CCNotify.m agganciato al pbxproj (4 voci)"
