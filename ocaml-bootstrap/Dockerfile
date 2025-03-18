FROM debian:stable

WORKDIR /root/bootstrap/sources

# Install external tools - these need not be built as they do not participate
# in the build process beyond menial tasks that could trivially be done by
# hand.
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
        && apt-get install -y git make

# Install build dependencies. The end goal of this project is to have none of
# these.
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y guile-3.0 gcc g++ libgmp-dev libmpfr-dev libmpc-dev flex

RUN git config --global protocol.file.allow always

RUN git clone --mirror git://gcc.gnu.org/git/gcc.git gcc.git

RUN git clone https://github.com/Ekdohibs/camlboot.git ocamlboot \
        && git -C ocamlboot reset --hard 2692b14a4e685387194556e511fe23057d25c6c3 \
        && git -C ocamlboot submodule update --init --recursive

RUN git clone --mirror https://github.com/ocaml/ocaml.git ocaml.git

COPY build.sh .

# Sanity check to ensure we don't accidentally use any prebuilt binaries.
RUN find . -type f -not -path '*.git/*' -exec grep -IL . "{}" \; | while read -r file; do \
            echo "Deleting binary file $file"; \
            rm "$file"; \
        done

CMD [ "./build.sh" ]
