FROM debian:stable

WORKDIR /root/bootstrap/sources

# Install external tools - these need not be built as they do not participate
# in the build process beyond menial tasks that could trivially (albeit
# painfully) be done by hand.
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
        && apt-get install -y git make file

# Install build dependencies. The end goal of this project is to have none of
# these.
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y guile-3.0 gcc g++ libgmp-dev libmpfr-dev libmpc-dev flex

RUN git config --global protocol.file.allow always \
        && git config --global advice.detachedHead false

RUN git clone --mirror --progress git://gcc.gnu.org/git/gcc.git gcc.git

RUN git clone --mirror --progress https://github.com/ocaml/ocaml.git ocaml.git

RUN git clone -s gcc.git gcc-11.5.0 \
        && git -C gcc-11.5.0 checkout releases/gcc-11.5.0

RUN git clone  --progress git://sourceware.org/git/glibc.git glibc-2.33 \
        # Check out the latest version of glibc that doesn't have a variable SIGSTKSZ
        # We won't actually compile this, we'll just use the headers it provides.
        # This is about as hacky as it gets :P
        && git -C glibc-2.33 checkout glibc-2.33

RUN git clone https://github.com/Ekdohibs/camlboot.git ocamlboot \
        && git -C ocamlboot checkout 2692b14a4e685387194556e511fe23057d25c6c3 \
        && git -C ocamlboot submodule update --init --recursive

COPY ocaml-ed74b5b-stage-1.patch ocaml-001997e-stage-1.patch .

# docker seems to struggle to build the container if these commands are put into separate
# RUN statements (specifically, the build process runs out of memory, so it may be able
# to build on a machine with more memory, but we don't want that to be a requirement).
RUN git clone -s ocaml.git ocaml-aa5a82e \
        && git -C ocaml-aa5a82e checkout aa5a82e7ae1607c3c45a495812bc4308a671c412 \
        # --- 
        && git clone -s ocaml.git ocaml-c4d0fec \
        && git -C ocaml-c4d0fec checkout c4d0fec0251883decc6e82fc243159b785c4e874 \
        # --- 
        && git clone -s ocaml.git ocaml-6da5262 \
        && git -C ocaml-6da5262 checkout 6da5262dd184d2437dc35a44a7af104d18d6d9ec \
        # --- 
        && git clone -s ocaml.git ocaml-ed74b5b-stage-1 \
        && git -C ocaml-ed74b5b-stage-1 checkout 0c9b121661b83ab249d069bf18dd4720b6d7fc3a \
        && git -C ocaml-ed74b5b-stage-1 checkout ed74b5b23711dc7516e828a921ade82301c345b4 -- stdlib \
        && git -C ocaml-ed74b5b-stage-1 apply ../ocaml-ed74b5b-stage-1.patch \
        # --- 
        && git clone -s ocaml.git ocaml-ed74b5b-stage-2 \
        && git -C ocaml-ed74b5b-stage-2 checkout ed74b5b23711dc7516e828a921ade82301c345b4 \
        # --- 
        && git clone -s ocaml.git ocaml-466d3bc \
        && git -C ocaml-466d3bc checkout 466d3bcc843e0bd4d7006577136f23b3b7b0abad \
        # --- 
        && git clone -s ocaml.git ocaml-430c20b \
        && git -C ocaml-430c20b checkout 430c20bb7812a4612101b4ed2f112e14fb2d1aee \
        # --- 
        && git clone -s ocaml.git ocaml-2d31ebf \
        && git -C ocaml-2d31ebf checkout 2d31ebfc8ba584e7ef51f3997a3bdcd061dbaa9c \
        # --- 
        && git clone -s ocaml.git ocaml-8e928ca \
        && git -C ocaml-8e928ca checkout 8e928caea7c47e6ba8508cf2caaaa1ba9f8dca85 \
        # --- 
        && git clone -s ocaml.git ocaml-b667fec \
        && git -C ocaml-b667fec checkout b667fec2e7f78d68cbf0ef012f34c41f5ad40b08 \
        # --- 
        && git clone -s ocaml.git ocaml-e9bb827 \
        && git -C ocaml-e9bb827 checkout e9bb827ff7e882c64066c2138038f53086d41db7 \
        # --- 
        && git clone -s ocaml.git ocaml-abc53d1 \
        && git -C ocaml-abc53d1 checkout abc53d1a6eab81beeb00afb2f980f89a84f6fa81 \
        # --- 
        && git clone -s ocaml.git ocaml-38eb6d5 \
        && git -C ocaml-38eb6d5 checkout 38eb6d5f6435ad3131935eb2b34bf8a8ef514e1e \
        # --- 
        && git clone -s ocaml.git ocaml-e1a22e8 \
        && git -C ocaml-e1a22e8 checkout e1a22e80fb2829b845b26c19c2c5aed3f17ab4c9 \
        # --- 
        && git clone -s ocaml.git ocaml-14a4510 \
        && git -C ocaml-14a4510 checkout 14a4510cb798804d76fbd45c41a215613dd60d12 \
        # --- 
        && git clone -s ocaml.git ocaml-6e3f710 \
        && git -C ocaml-6e3f710 checkout 6e3f710d78e7ed6799df4e82351acb26850d5a15 \
        # --- 
        && git clone -s ocaml.git ocaml-0ca651b \
        && git -C ocaml-0ca651b checkout 0ca651b95cbda5d58f7760f0fa1dba965d1f0828 \
        # --- 
        && git clone -s ocaml.git ocaml-a1f2166 \
        && git -C ocaml-a1f2166 checkout a1f21661a488dad9dd2ebafe0ccd484c6e4e7d5e \
        # --- 
        && git clone -s ocaml.git ocaml-b0cd12d \
        && git -C ocaml-b0cd12d checkout b0cd12d1c48fb22d7d06d49c7976bccce7d58068 \
        # --- 
        && git clone -s ocaml.git ocaml-0a11f73 \
        && git -C ocaml-0a11f73 checkout 0a11f73c8bde08ec0c0291d525e635c71f3237ec \
        # --- 
        && git clone -s ocaml.git ocaml-46cec11 \
        && git -C ocaml-46cec11 checkout 46cec117a462cc221a56eba049ce59cb6e68e38f \
        # --- 
        && git clone -s ocaml.git ocaml-1c9e1e0 \
        && git -C ocaml-1c9e1e0 checkout 1c9e1e0811f9ac231c789fd9dfd4a1236acae7d2 \
        # --- 
        && git clone -s ocaml.git ocaml-40399cc \
        && git -C ocaml-40399cc checkout 40399cca5e21747395a656e5f367e2d7d148559f \
        # --- 
        && git clone -s ocaml.git ocaml-de4377e \
        && git -C ocaml-de4377e checkout de4377e843b8e591ac12f9dd54db9c14d34e0811 \
        # --- 
        && git clone -s ocaml.git ocaml-49aa87c \
        && git -C ocaml-49aa87c checkout 49aa87c316c441aa47974e8e9191a5a7e6d03d9a \
        # --- 
        && git clone -s ocaml.git ocaml-eb342da \
        && git -C ocaml-eb342da checkout eb342da8a9cdbce0760b91c9b9d5e682ed0d4496 \
        # --- 
        && git clone -s ocaml.git ocaml-8420c3e \
        && git -C ocaml-8420c3e checkout 8420c3ea9f126fd9af57c6193c90f60ae4250e51 \
        # --- 
        && git clone -s ocaml.git ocaml-55973d1 \
        && git -C ocaml-55973d1 checkout 55973d1203e290709f30dcda443311fac0e371e1 \
        # --- 
        && git clone -s ocaml.git ocaml-254963a \
        && git -C ocaml-254963a checkout 254963a29eafb9c55cbaaa1289d46e6606c17a07 \
        # --- 
        && git clone -s ocaml.git ocaml-6d3e9af \
        && git -C ocaml-6d3e9af checkout 6d3e9af47707714fb41c7d457152c431b7bc5d59 \
        # --- 
        && git clone -s ocaml.git ocaml-06ede5f \
        && git -C ocaml-06ede5f checkout 06ede5fdf5ad116ad720060c94ab1a704533f31c \
        # --- 
        && git clone -s ocaml.git ocaml-0ba253d \
        && git -C ocaml-0ba253d checkout 0ba253df4667668bc01dd9e239fba13f743e1752 \
        # --- 
        && git clone -s ocaml.git ocaml-dd7927e \
        && git -C ocaml-dd7927e checkout dd7927e156b7cb2f9cb73d2d54a15a9c81921392 \
        # --- 
        && git clone -s ocaml.git ocaml-2250fd8 \
        && git -C ocaml-2250fd8 checkout 2250fd8a2218796c07b0a25f184cdc682e4695ba \
        # --- 
        && git clone -s ocaml.git ocaml-f310f74 \
        && git -C ocaml-f310f74 checkout f310f749bdb2979424e9e8caed6ef97afe3ccf9c \
        # --- 
        && git clone -s ocaml.git ocaml-c83bd4a \
        && git -C ocaml-c83bd4a checkout c83bd4a3b00dd399a0bb86a59f843f927bddb04e \
        # --- 
        && git clone -s ocaml.git ocaml-001997e-stage-1 \
        && git -C ocaml-001997e-stage-1 checkout 001997e81342fd0d321fd877b73608150601e7d9 \
        && git -C ocaml-001997e-stage-1 apply ../ocaml-001997e-stage-1.patch \
        # --- 
        && git clone -s ocaml.git ocaml-001997e-stage-2 \
        && git -C ocaml-001997e-stage-2 checkout 001997e81342fd0d321fd877b73608150601e7d9 \
        # --- 
        && git clone -s ocaml.git ocaml-fad280b \
        && git -C ocaml-fad280b checkout fad280bc779a4afd91844a86dfe91357a40f91fb \
        # --- 
        && git clone -s ocaml.git ocaml-320baa9 \
        && git -C ocaml-320baa9 checkout 320baa96c09effc8e9eb1272559eccc6e51dec60 \
        # --- 
        && git clone -s ocaml.git ocaml-fe66f6a \
        && git -C ocaml-fe66f6a checkout fe66f6a6edee73ab9dbbb75aa79d42283601ea80 \
        # --- 
        && git clone -s ocaml.git ocaml-43c9026 \
        && git -C ocaml-43c9026 checkout 43c9026a9a47fcbdf2e827fecd022f559f206fb2 \
        # --- 
        && git clone -s ocaml.git ocaml-9727182 \
        && git -C ocaml-9727182 checkout 972718291dfcf9e3dd79b2567510eb00ade156d0 \
        # --- 
        && git clone -s ocaml.git ocaml-cf3d9e9 \
        && git -C ocaml-cf3d9e9 checkout cf3d9e9c3f9de49284ccf0b139a3d70223ec2358 \
        # --- 
        && git clone -s ocaml.git ocaml-655bb25 \
        && git -C ocaml-655bb25 checkout 655bb25da31defb746a2f5e218f0a7429e86ac50 \
        # --- 
        && git clone -s ocaml.git ocaml-3e9642c \
        && git -C ocaml-3e9642c checkout 3e9642c0f576725454d2b74f08bee5d3d5238526 \
        # --- 
        && git clone -s ocaml.git ocaml-15aa778 \
        && git -C ocaml-15aa778 checkout 15aa778908f10e804bacda77a9065338324a8dd7 \
        # --- 
        && git clone -s ocaml.git ocaml-c48fb71 \
        && git -C ocaml-c48fb71 checkout c48fb71f60c093d7186c9654b2b3d87a2784061b \
        # --- 
        && git clone -s ocaml.git ocaml-6d934fe \
        && git -C ocaml-6d934fe checkout 6d934febd1fc111d76ed5789745ecab6bcadb019 \
        # --- 
        && git clone -s ocaml.git ocaml-411174a \
        && git -C ocaml-411174a checkout 411174a19d3d8665ccf8d7853ec3855924f24f07 \
        # --- 
        && git clone -s ocaml.git ocaml-b6ecc23 \
        && git -C ocaml-b6ecc23 checkout b6ecc23744a7766380093146e3396bcb4917a8af \
        # --- 
        && git clone -s ocaml.git ocaml-167c070 \
        && git -C ocaml-167c070 checkout 167c070cc37c0830e8b9396c44eb9cd7beceb98f \
        # --- 
        && git clone -s ocaml.git ocaml-bdcadbe \
        && git -C ocaml-bdcadbe checkout bdcadbe1cb0c4fc9fdbe154e647fe8b3120703fc \
        # --- 
        && git clone -s ocaml.git ocaml-a36a533 \
        && git -C ocaml-a36a533 checkout a36a53377d983e06f6b2cfd52b30f429d19c1cae \
        # --- 
        && git clone -s ocaml.git ocaml-b2cd7e5 \
        && git -C ocaml-b2cd7e5 checkout b2cd7e59e5b563b6a0527014689b7224bb678661 \
        # --- 
        && git clone -s ocaml.git ocaml-db150fc \
        && git -C ocaml-db150fc checkout db150fcebb27f4cd76591081e04b62da6f11cf3b \
        # --- 
        && git clone -s ocaml.git ocaml-87a5cce \
        && git -C ocaml-87a5cce checkout 87a5cce7f2c207f526288508949057afbf0c04c9 \
        # --- 
        && git clone -s ocaml.git ocaml-23f1072 \
        && git -C ocaml-23f1072 checkout 23f1072ee7337cc65beb69839dfc391ff64233ff \
        # --- 
        && git clone -s ocaml.git ocaml-5.3.0 \
        && git -C ocaml-5.3.0 checkout 5.3.0

COPY build.sh hello_world.ml .

# Sanity check to ensure we don't accidentally use any prebuilt binaries.
RUN find . -type f -not -path '*.git/*' -size +16c -exec grep -IL . "{}" \; | while read -r file; do \
            echo "Deleting binary file $file"; \
            rm "$file"; \
        done

CMD [ "./build.sh" ]
