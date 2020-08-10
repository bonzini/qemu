#!/bin/bash

OUTFILE="$1"
PREFIX="$2"
SRCDIR="$3"
CPU="$4"

DESTDIR=$(mktemp -d)
trap "rm -rf $DESTDIR" EXIT
make DESTDIR="$DESTDIR" install

signcode() {
    if [ -z "$SIGNCODE" ]; then
        return
    fi
    "$SIGNCODE" "$@"
}

shopt -s nullglob

(
    cd "$DESTDIR$PREFIX"
    for i in qemu-system-*.exe; do
        arch=${i%.exe}
        arch=${arch#qemu-system-}
        echo Section \"$arch\" Section_$arch
        echo SetOutPath \"\$INSTDIR\"
        echo File \"\${BINDIR}\\$i\"
        echo SectionEnd
    done
) > "$DESTDIR$PREFIX/system-emulations.nsh"

(
    cd "$DESTDIR$PREFIX"
    for i in *.exe; do
        signcode "$i"
    done
)

if [ "$CPU" = "x86_64" ]; then
    CPUARG="-DW64"
    DLLDIR="w64"
else
    DLLDIR="w32"
fi

if [ -d "$SRCDIR/dll" ]; then
   DLLARG="-DDLLDIR=$SRCDIR/dll/$DLLDIR"
fi

makensis -V2 -NOCD -DSRCDIR="$SRCDIR" -DBINDIR="$DESTDIR$PREFIX" \
         $CPUARG $DLLARG -DOUTFILE="$OUTFILE" "$@"

signcode "$OUTFILE"
