#!/bin/bash

ROOT="/root/bootstrap"
SOURCES="$ROOT/sources"
DEPENDENCIES="$ROOT/dependencies"
OVERLAY="$ROOT/overlay"
BOOTSTRAP_ROOT="$ROOT/merged"

if [[ ! -e "/build.sh" ]]; then
    overlay_store="$ROOT/overlayfs"
    [[ -d "$BOOTSTRAP_ROOT" ]] && { umount -q "$BOOTSTRAP_ROOT"; rm -rf "$BOOTSTRAP_ROOT"; }
    [[ -d "$OVERLAY" ]] && { umount -q "$OVERLAY"; rm -rf "$OVERLAY" "$overlay_store"; }
    [[ -d "$DEPENDENCIES" ]] && { umount -q "$DEPENDENCIES"; rm -rf "$DEPENDENCIES"; }
    
    # Create a 1TB sparse file to contain the filesystem.
    dd status=none if=/dev/null bs=1 seek=1024000000000 "of=$overlay_store"
    mkfs.ext4 -q "$overlay_store"
    mkdir -p "$OVERLAY"
    mount -o discard "$overlay_store" "$OVERLAY"

    # Setup dependencies.
    mkdir -p "$DEPENDENCIES/"{dev,tmp,usr/lib,usr/bin,usr/lib64}

    # Menial task automation. We don't need to replace these.
    cp /bin/{bash,ls,make,nproc,rm,find,xargs,touch,cp,sh,sed,mkdir,cat,uname,head,grep,tr,sort,uniq,chmod,expr,ln,awk,mv,ar,env,date,rmdir,egrep,diff,sleep,cmp,ranlib,strip,file,arch,hostname,dirname,basename,true,gzip,tar,cut,patch,wc,tail} \
        "$DEPENDENCIES/usr/bin/"

    # Link "$DEPENDENCIES/bin" to "$DEPENDENCIES/usr/bin" - not the real /usr/bin
    ln -s "usr/bin" "$DEPENDENCIES/bin"

    # Copy include files for the default GCC installation & system headers.
    cp -r /usr/include "$DEPENDENCIES/usr/"

    # These are a little more controversial...
    cp -r /usr/lib/ "$DEPENDENCIES/usr/"
    cp -r /usr/lib64/ "$DEPENDENCIES/usr/"
    ln -s "usr/lib" "$DEPENDENCIES/lib"
    ln -s "usr/lib64" "$DEPENDENCIES/lib64"

    # We definitely need to replace these.
    cp /bin/{gcc,g++,flex,m4,as,nm,objcopy,objdump,readelf,ld} "$DEPENDENCIES/bin"

    cp "$0" "$DEPENDENCIES" # Workaround for bind mount in devcontainer

    cp -a /dev/null "$DEPENDENCIES/dev/null"

    mkdir -p "$OVERLAY/upper" "$OVERLAY/work"
    mkdir -p "$BOOTSTRAP_ROOT"
    mount -t overlay overlay -o "lowerdir=$DEPENDENCIES:$SOURCES,upperdir=$OVERLAY/upper,workdir=$OVERLAY/work" "$BOOTSTRAP_ROOT"

    exec chroot "$BOOTSTRAP_ROOT" bash /build.sh
fi

set -euo pipefail

export PATH="/usr/local/bin:/usr/bin:/bin:/usr/lib/gcc/x86_64-linux-gnu/12"

cd /gcc-11.5.0
mkdir objdir
cd objdir

echo "experimental" > ../gcc/DEV-PHASE
../configure --disable-multilib --enable-languages=c

make -j$(nproc) bootstrap
make install


cd /libffi-3.4.8

./configure --disable-docs
make -j$(nproc)
make install


cd /gc-8.2.8

./configure
make -j$(nproc)
make install


cd /libunistring-1.3 

./configure
make -j$(nproc)
make install


cd /guile-3.0.10

# Binary doc files that were removed, but that `make` depends on for generating
# docs.
touch doc/ref/hierarchy.pdf
touch doc/ref/hierarchy.png
touch doc/ref/gds.pdf
touch doc/ref/scheme.pdf

# *_CFLAGS must be non-empty to skip pkg-config
LIBFFI_CFLAGS=" " LIBFFI_LIBS="-lffi" \
    BDW_GC_CFLAGS=" " BDW_GC_LIBS="-lgc -lpthread -ldl" \
    ./configure
make -j$(nproc)
make install


cd /ocamlboot

# Temporarily use old SIGSTKSZ. This doesn't affect the generated binary at
# runtime.
# See https://github.com/ocaml/ocaml/commit/632563b19ca72ec0ae10c7ed767a025c342d3155
# for why this is required. We can't just cherry-pick the commit as there are
# several conflicts, so it's easier to just reproduce the older glibc
# environment seeing as the change is header-only.
mv /usr/include/signal.h /usr/include/signal.h.old
cp /glibc-2.33/signal/signal.h /usr/include/signal.h

make -j$(nproc) _boot/ocamlc
make -j$(nproc) fullboot

# Undo our stupidity.
rm /usr/include/signal.h
mv /usr/include/signal.h.old /usr/include/signal.h


cd /ocaml-aa5a82e

# OCaml, at minimum, requires two binary files to bootstrap itself: ocamllex and
# ocamlc (both of which are bytecode files). Using these files and a C compiler,
# the build process first builds the C runtime, which is used to run ocamlc and
# ocamllex to build the standard library (coldstart). This standard library is
# then used to build a new version of ocamlc and ocamllex, which are then used
# to recompile the standard library with the new compilers (coreall).
# This new version of ocamlc and ocamllex then replaces the old ocamlc and
# ocamllex, and rebuild themselves to ensure stability in the compiled output
# (coreboot).
# Usually, the ocamlc and ocamllex used to start one version's bootstrap would
# be taken from the previous version's boot/ directory (where coreboot places
# the newly built compilers), but in the case of ocamlboot, the ocamlc present
# in the boot directory is a native executable, and not a bytecode file, which
# confuses the build process. So, we instead copy the ocamlc from the root of
# the ocaml-src tree.
cp -L /ocamlboot/ocaml-src/boot/ocamllex /ocamlboot/ocaml-src/ocamlc boot/

./configure
# GCC 10+ defaults to -fno-common, which breaks this version of OCaml.
# See https://github.com/ocaml/ocaml/pull/9180.
echo 'OC_CFLAGS+=-fcommon' >> Makefile.config
echo 'OCAMLC_CFLAGS+=-fcommon' >> Makefile.config

make -j$(nproc) coldstart
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-c4d0fec

cp -L /ocaml-aa5a82e/boot/{ocamlc,ocamllex} boot/

./configure
echo 'OC_CFLAGS+=-fcommon' >> Makefile.config
echo 'OCAMLC_CFLAGS+=-fcommon' >> Makefile.config

make -j$(nproc) coldstart
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-6da5262

# In some instances, the C runtime from the "new" OCaml is unable to run the
# ocamlc and ocamllex copied from the "old" OCaml (in this case, because the
# magic number for bytecode executables changed).
# For these instances, the bootstrap process is slightly different. Instead of
# using coldstart to build the new C runtime and new stdlib, we instead copy
# over the entire boot/ directory of the old OCaml, which contains a copy of the
# old runtime and compiled stdlib. The build then proceeds as normal, building
# ocamlc and ocamllex, and then using them to compile the new stdlib (coreall).
# The coreboot stage now gains one new responsiblity: it is now also responsible
# for taking the versions of ocamlc and ocamllex that were just built by the old
# ocamlc, and therefore run on the old runtime, and using them to build a new
# ocamlc anc ocamllex that run on the new runtime.
cp -rL /ocaml-c4d0fec/boot/* boot

# Two more files must sometimes be copied over from the old OCaml: opnames.ml
# and opcodes.ml. These files are generated by tools/make_opcodes, built by the
# old ocamlc from tools/make_opcodes.ml, but run on the new runtime - which can
# fail, as the old ocamlc generates bytecode for the old runtime.
# The ordering is important, these files all depend on each other in Make and so
# they must be created in the order they are depended on, or they will be
# rebuilt.
touch tools/make_opcodes.ml
touch tools/make_opcodes
cp /ocaml-c4d0fec/tools/opnames.ml tools
cp /ocaml-c4d0fec/bytecomp/opcodes.ml bytecomp

./configure
echo 'OC_CFLAGS+=-fcommon' >> Makefile.config
echo 'OCAMLC_CFLAGS+=-fcommon' >> Makefile.config

make -j$(nproc) coreall
make -j$(nproc) coreboot


# https://github.com/ocaml/ocaml/commit/ed74b5b23711dc7516e828a921ade82301c345b4
# updates both stdlib and ocamlc in lockstep. Attempting to compile ocamlc first
# fails, as it depends on the new standard library, so we cannot start with
# coreall, but compiling stdlib first also fails as older versions of ocamlc
# generate incompatible format ASTs, so we cannot coldstart.
#
# Therefore, perform a two stage update: first compile a patched ocamlc that
# generates a dummy format AST that is compatible with the new stdlib, but still
# only depends on the old stdlib itself, then use that new ocamlc to compile the
# standard library.
# We can then (in ocaml-ed74b5b-stage-2) use the new standard library to compile
# the new ocamlc from ed74b5b23711dc7516e828a921ade82301c345b4 which generates
# the correct format AST for the new runtime, and can finally be used to
# recompile the new stdlib (in order to get correct format ASTs instead of the
# dummy ones we introduced in stage 1), completing the bootstrap.
cd /ocaml-ed74b5b-stage-1

cp -rL /ocaml-6da5262/boot/* boot

./configure
echo 'OC_CFLAGS+=-fcommon' >> Makefile.config
echo 'OCAMLC_CFLAGS+=-fcommon' >> Makefile.config

make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-ed74b5b-stage-2

cp -rL /ocaml-ed74b5b-stage-1/boot/* boot

./configure
echo 'OC_CFLAGS+=-fcommon' >> Makefile.config
echo 'OCAMLC_CFLAGS+=-fcommon' >> Makefile.config

make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-466d3bc

cp -rL /ocaml-ed74b5b-stage-2/boot/* boot

./configure
echo 'OC_CFLAGS+=-fcommon' >> Makefile.config
echo 'OCAMLC_CFLAGS+=-fcommon' >> Makefile.config

# Like coldstart, but don't build the stdlib.
make -j$(nproc) -C runtime all
cp runtime/ocamlrun boot
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-430c20b

cp /ocaml-466d3bc/boot/{ocamlc,ocamllex} boot

./configure
echo 'OC_CFLAGS+=-fcommon' >> Makefile.config
echo 'OCAMLC_CFLAGS+=-fcommon' >> Makefile.config

make -j$(nproc) coldstart
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-2d31ebf

cp -rL /ocaml-430c20b/boot/* boot

./configure
echo 'OC_CFLAGS+=-fcommon' >> Makefile.config
echo 'OCAMLC_CFLAGS+=-fcommon' >> Makefile.config

make -j$(nproc) coreall
make -j$(nproc) coreboot

cd /ocaml-8e928ca

cp /ocaml-2d31ebf/boot/{ocamlc,ocamllex} boot

./configure
echo 'OC_CFLAGS+=-fcommon' >> Makefile.config
echo 'OCAMLC_CFLAGS+=-fcommon' >> Makefile.config

make -j$(nproc) coldstart
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-b667fec

cp /ocaml-8e928ca/boot/{ocamlc,ocamllex} boot

./configure
echo 'OC_CFLAGS+=-fcommon' >> Makefile.config
echo 'OCAMLC_CFLAGS+=-fcommon' >> Makefile.config

make -j$(nproc) coldstart
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-e9bb827

cp -rL /ocaml-b667fec/boot/* boot

touch tools/make_opcodes.ml
touch tools/make_opcodes
cp /ocaml-b667fec/tools/opnames.ml tools
cp /ocaml-b667fec/bytecomp/opcodes.ml bytecomp

./configure
echo 'OC_CFLAGS+=-fcommon' >> Makefile.config
echo 'OCAMLC_CFLAGS+=-fcommon' >> Makefile.config

make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-abc53d1

cp /ocaml-e9bb827/boot/{ocamlc,ocamllex} boot

./configure
echo 'OC_CFLAGS+=-fcommon' >> Makefile.config
echo 'OCAMLC_CFLAGS+=-fcommon' >> Makefile.config

make -j$(nproc) coldstart
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-38eb6d5

cp /ocaml-abc53d1/boot/{ocamlc,ocamllex} boot

# -fcommon is no longer needed from https://github.com/ocaml/ocaml/commit/64eb707715b677ef98372a521264e91e67c35205
# onwards.
./configure
make -j$(nproc) coldstart
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-e1a22e8

# https://github.com/ocaml/ocaml/commit/e1a22e80fb2829b845b26c19c2c5aed3f17ab4c9
# removes the use of a primitive from the stdlib and from the runtime in the
# same commit. Usually, this is done in two separate commits, as a coldstart is
# impossible (the old ocamlc cannot run on the new runtime as it depends on the
# removed primitive), and the old ocamlc will also be informed of the available
# primitives in the new runtime (via -use-prims runtime/primitives), and will
# error while linking the old stdlib (which depends on the removed primitive) to
# the new ocamlc, even though the primitive would be fine to use as the new
# ocamlc would still run on the old runtime (before coreboot).
# We therefore avoid the issue by copying forward a primitives list from an
# older version and building the new ocamlc with that primitive list.
cp -rL /ocaml-38eb6d5/boot/* boot
cp /ocaml-38eb6d5/runtime/primitives runtime

touch tools/make_opcodes.ml
touch tools/make_opcodes
cp /ocaml-38eb6d5/tools/opnames.ml tools
cp /ocaml-38eb6d5/bytecomp/opcodes.ml bytecomp

./configure
# Don't use coreall as we need to build the runtime after we have built ocamlc
# and the other core members, else runtime/primtives would be rebuilt.
make -j$(nproc) utils/clflags.cmi
make -j$(nproc) ocamlc
make -j$(nproc) ocamllex ocamltools library
make -j$(nproc) -C runtime all
make -j$(nproc) coreboot

# Technically the same trick is not required here (the removal was correctly
# performed over two commits), but we can skip building the first one this way.
cd /ocaml-14a4510

cp -rL /ocaml-e1a22e8/boot/* boot
cp /ocaml-e1a22e8/runtime/primitives runtime

touch tools/make_opcodes.ml
touch tools/make_opcodes
cp /ocaml-e1a22e8/tools/opnames.ml tools
cp /ocaml-e1a22e8/bytecomp/opcodes.ml bytecomp

./configure
make -j$(nproc) ocamlc
make -j$(nproc) ocamllex ocamltools library
make -j$(nproc) -C runtime all
make -j$(nproc) coreboot


cd /ocaml-6e3f710

cp -L /ocaml-14a4510/boot/{ocamlc,ocamllex} boot

./configure
make -j$(nproc) coldstart
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-0ca651b

cp -rL /ocaml-6e3f710/boot/* boot

./configure
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-a1f2166

cp -rL /ocaml-0ca651b/boot/* boot

touch tools/make_opcodes.ml
touch tools/make_opcodes
cp /ocaml-0ca651b/tools/opnames.ml tools
cp /ocaml-0ca651b/bytecomp/opcodes.ml bytecomp

./configure
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-b0cd12d

cp -L /ocaml-a1f2166/boot/{ocamlc,ocamllex} boot

./configure
make -j$(nproc) coldstart
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-0a11f73

cp -rL /ocaml-b0cd12d/boot/* boot

./configure
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-46cec11

cp -L /ocaml-0a11f73/boot/{ocamlc,ocamllex} boot

./configure
make -j$(nproc) coldstart
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-1c9e1e0

cp -rL /ocaml-46cec11/boot/* boot

./configure
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-40399cc

cp -L /ocaml-1c9e1e0/boot/{ocamlc,ocamllex} boot

./configure
make -j$(nproc) coldstart
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-de4377e

cp -rL /ocaml-40399cc/boot/* boot

./configure
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-49aa87c

cp -L /ocaml-de4377e/boot/{ocamlc,ocamllex} boot

./configure
make -j$(nproc) coldstart
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-eb342da

cp -L /ocaml-49aa87c/boot/{ocamlc,ocamllex} boot

./configure
make -j$(nproc) coldstart
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-8420c3e

cp -rL /ocaml-eb342da/boot/* boot

./configure
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-55973d1

cp -rL /ocaml-8420c3e/boot/* boot

touch tools/make_opcodes.ml
touch tools/make_opcodes
cp /ocaml-8420c3e/tools/opnames.ml tools
cp /ocaml-8420c3e/bytecomp/opcodes.ml bytecomp

./configure
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-254963a

cp -L /ocaml-55973d1/boot/{ocamlc,ocamllex} boot

./configure
make -j$(nproc) coldstart
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-6d3e9af

cp -rL /ocaml-254963a/boot/* boot

./configure
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-06ede5f

cp -L /ocaml-6d3e9af/boot/{ocamlc,ocamllex} boot

./configure
make -j$(nproc) coldstart
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-0ba253d

cp -L /ocaml-06ede5f/boot/{ocamlc,ocamllex} boot

./configure
make -j$(nproc) coldstart
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-dd7927e

cp -rL /ocaml-0ba253d/boot/* boot

touch tools/make_opcodes.ml
touch tools/make_opcodes
cp /ocaml-0ba253d/tools/opnames.ml tools
cp /ocaml-0ba253d/bytecomp/opcodes.ml bytecomp

./configure
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-2250fd8

cp -L /ocaml-dd7927e/boot/{ocamlc,ocamllex} boot

./configure
make -j$(nproc) coldstart
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-f310f74

cp -rL /ocaml-2250fd8/boot/* boot

touch tools/make_opcodes.ml
touch tools/make_opcodes
cp /ocaml-2250fd8/tools/opnames.ml tools
cp /ocaml-2250fd8/bytecomp/opcodes.ml bytecomp

./configure
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-c83bd4a

cp -rL /ocaml-f310f74/boot/* boot

./configure
make -j$(nproc) coreall
make -j$(nproc) coreboot


# https://github.com/ocaml/ocaml/commit/001997e81342fd0d321fd877b73608150601e7d9
# is the merge commit introducing the entire ocaml-multicore tree into mainline
# ocaml. This results in incompatiblities in the runtime (new primitives added &
# some primitives removed), and in ocamlc (which makes use of variables only
# declared in ocaml-multicore's stdlib, which we don't have a compiled version
# of at this point).
# Luckily, we can patch the ocamlc sources with minimal effort to remove that
# reliance on ocaml-multicore's stdlib, and build it with the stdlib we
# currently have. We then perform another bootstrap on a "clean" checkout of
# 001997e to reach a stable state.
# A better solution would have been to follow ocaml-multicore's tree instead of
# ocaml's as they regularly pulled changes from mainline ocaml into their own
# tree. Oh well.
cd /ocaml-001997e-stage-1

cp -rL /ocaml-c83bd4a/boot/* boot
cp /ocaml-c83bd4a/runtime/primitives runtime

touch tools/make_opcodes.ml
touch tools/make_opcodes
cp /ocaml-c83bd4a/tools/opnames.ml tools
cp /ocaml-c83bd4a/bytecomp/opcodes.ml bytecomp

./configure
make -j$(nproc) ocamlc
make -j$(nproc) ocamllex ocamltools library
make -j$(nproc) -C runtime all
# This bootstrap not being stable is fine, it will be corrected in stage 2.
make -j$(nproc) coreboot || true


cd /ocaml-001997e-stage-2

cp -rL /ocaml-001997e-stage-1/boot/* boot

./configure
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-fad280b

cp -L /ocaml-001997e-stage-2/boot/{ocamlc,ocamllex} boot

./configure
make -j$(nproc) coldstart
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-320baa9

cp -rL /ocaml-fad280b/boot/* boot

./configure
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-fe66f6a

cp -L /ocaml-320baa9/boot/{ocamlc,ocamllex} boot

./configure
make -j$(nproc) coldstart
make -j$(nproc) coreall
make -j$(nproc) coreboot


# https://github.com/ocaml/ocaml/commit/43c9026a9a47fcbdf2e827fecd022f559f206fb2
# is also a problematic commit, but we can avoid doing a two-stage bootstrap by
# building coreall "as if" we were in a coreboot cycle - that is, by building
# library-cross instead of library.
cd /ocaml-43c9026

cp -rL /ocaml-fe66f6a/boot/* boot

./configure
make -j$(nproc) runtime
make -j$(nproc) ocamlc
make -j$(nproc) ocamltools ocamllex
make -j$(nproc) library-cross
# We need to manually promote ocamlrun as coreboot assumes the ocamlc we just
# compiled can run on boot/ocamlrun, which isn't the case here as the new ocamlc
# declares a primitive added to the runtime (even if it doesn't use it), and the
# old runtime therefore refuses to run it.
# This is normally handled by coldstart.
cp runtime/ocamlrun boot
make -j$(nproc) coreboot


cd /ocaml-9727182

cp -rL /ocaml-43c9026/boot/* boot

./configure
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-cf3d9e9

cp -rL /ocaml-9727182/boot/* boot

touch tools/make_opcodes.ml
touch tools/make_opcodes
cp /ocaml-9727182/tools/opnames.ml tools
cp /ocaml-9727182/bytecomp/opcodes.ml bytecomp

./configure
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-655bb25

cp -L /ocaml-cf3d9e9/boot/{ocamlc,ocamllex} boot

./configure
make -j$(nproc) coldstart
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-3e9642c

cp -rL /ocaml-655bb25/boot/* boot

# There are now more generated files to mock - make_opcodes now depends on
# make_opcodes.cmi and make_opcodes.cmo.
touch tools/make_opcodes.ml
touch tools/make_opcodes.cmi
touch tools/make_opcodes.cmo
touch tools/make_opcodes
cp /ocaml-655bb25/tools/opnames.ml tools
cp /ocaml-655bb25/bytecomp/opcodes.ml bytecomp

./configure
make -j$(nproc) coreall
# opcodes.ml and opnames.ml are forcefully rebuilt by coreboot from this point
# on, so we need tools/make_opcodes to be correct. However, we just created a
# dummy empty file to fool the coreall build into skipping them.
# Remove tools/make_opcodes.ml so it (and all its dependents) are rebuilt
# correctly in the coreboot cycle.
rm tools/make_opcodes.ml
make -j$(nproc) coreboot


cd /ocaml-15aa778

cp -L /ocaml-3e9642c/boot/{ocamlc,ocamllex} boot

./configure
make -j$(nproc) coldstart
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-c48fb71

cp -L /ocaml-15aa778/boot/{ocamlc,ocamllex} boot

./configure
make -j$(nproc) coldstart
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-6d934fe

cp -rL /ocaml-c48fb71/boot/* boot

./configure
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-411174a

cp -rL /ocaml-6d934fe/boot/* boot

./configure
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-b6ecc23

cp -L /ocaml-411174a/boot/{ocamlc,ocamllex} boot

./configure
make -j$(nproc) coldstart
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-167c070

cp -rL /ocaml-b6ecc23/boot/* boot

./configure
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-bdcadbe

cp -L /ocaml-167c070/boot/{ocamlc,ocamllex} boot

./configure
make -j$(nproc) coldstart
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-a36a533

cp -rL /ocaml-bdcadbe/boot/* boot

touch tools/make_opcodes.ml
touch tools/make_opcodes.cmi
touch tools/make_opcodes.cmo
touch tools/make_opcodes
cp /ocaml-bdcadbe/tools/opnames.ml tools
cp /ocaml-bdcadbe/bytecomp/opcodes.ml bytecomp

./configure
make -j$(nproc) coreall
rm tools/make_opcodes.ml
make -j$(nproc) coreboot


cd /ocaml-b2cd7e5

cp -L /ocaml-a36a533/boot/{ocamlc,ocamllex} boot

./configure
make -j$(nproc) coldstart
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-db150fc

cp -rL /ocaml-b2cd7e5/boot/* boot

./configure
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-87a5cce

cp -L /ocaml-db150fc/boot/{ocamlc,ocamllex} boot

./configure
make -j$(nproc) coldstart
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-23f1072

cp -L /ocaml-87a5cce/boot/{ocamlc,ocamllex} boot

./configure
make -j$(nproc) coldstart
make -j$(nproc) coreall
make -j$(nproc) coreboot


cd /ocaml-5.3.0

cp -L /ocaml-23f1072/boot/{ocamlc,ocamllex} boot

./configure
make -j$(nproc) coldstart
make -j$(nproc) coreall
# Use bootstrap instead of coreboot to build additional tools that install
# requires.
make -j$(nproc) bootstrap
# Override INSTALL to remove the -p switch, which is unsupported but still
# somehow added by default in the makefile. build-aux/install-sh might be a
# fallback that isn't accounted for that we end up using because of a missing
# program in the chroot.
# INSTALL is interpreted as a relative path both from the root ocaml directory
# and from the stdlib directory - which will never point to the same location.
# So we need to use an absolute path.
# Uncertain on how this is ever supposed to work without providing a manual
# absolute override.
make INSTALL='/ocaml-5.3.0/build-aux/install-sh -c' install

cd /
echo

ocamlc hello_world.ml -o hello_world
./hello_world
