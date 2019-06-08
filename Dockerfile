FROM ksteimel/julia:latest

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    ca-certificates \
        autoconf \
        build-essential \
        git \
        mc \
        nano \
        curl \
    ; \
    rm -rf /var/lib/apt/lists/*

RUN julia -O3 -e 'using Pkg;;Pkg.REPLMode.pkgstr("add Luxor;precompile");using Luxor'
RUN julia -O3 -e 'using Pkg;Pkg.REPLMode.pkgstr("add AbstractTrees;precompile");using AbstractTrees'

WORKDIR /projects
