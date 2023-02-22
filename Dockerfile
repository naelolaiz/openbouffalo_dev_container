FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
ENV BR_BOUFFALO_OVERLAY_PATH=/src/buildroot_bouffalo

RUN apt-get update && apt-get install -y make gcc g++ unzip git bc python3 device-tree-compiler mtd-utils xz-utils file wget cpio rsync bzip2 libncurses-dev mc

RUN mkdir src && cd src && git clone https://github.com/buildroot/buildroot && git clone https://github.com/openbouffalo/buildroot_bouffalo && export BR_BOUFFALO_OVERLAY_PATH=$(pwd)/buildroot_bouffalo && cd buildroot && make BR2_EXTERNAL=$BR_BOUFFALO_OVERLAY_PATH pine64_ox64_defconfig && make

CMD [ "/bin/bash" ]


#
#
#name: build-all
#
#on:
#  workflow_dispatch:
#  push:
#    branches: [ main ]
#    paths-ignore:
#      - '.github/**'
#    tags:
#      - "v*.*.*"
#  pull_request:
#    branches: [ main ]
#    paths-ignore:
#      - '.github/**'
#    
#jobs:
#  buildroot:
#    strategy:
#      fail-fast: true
#      matrix:
#        target: [ pine64_ox64_defconfig, pine64_ox64_full_defconfig ]
#    runs-on: ubuntu-22.04
#    steps:
#    - name: install dependencies
#      run: |
#        sudo apt-get install -y make gcc g++ unzip git bc python3 device-tree-compiler mtd-utils xz-utils
#    - name: Checkout Buildroot sources
#      uses: actions/checkout@v3
#      with:
#        repository: buildroot/buildroot
#        ref: 2022.11.1
#        path: buildroot
#    - name: Checkout OpenBouffalo Buildroot
#      uses: actions/checkout@v3
#      with:
#        path: buildroot_bouffalo
#    - name: buildroot ccache
#      id: br-ccache
#      uses: actions/cache@v3
#      env:
#        cache-name: br-ccache
#      with:
#        path: /home/runner/.buildroot-ccache
#        key: ${{ runner.os }}-build-${{ env.cache-name }}-${{ matrix.target }}
#    - name: buildroot download cache
#      uses: actions/cache@v3
#      env:
#        cache-name: cache-download-files
#      with:
#        path: ${{ github.workspace }}/buildroot/dl/
#        key: ${{ runner.os }}-build-${{ env.cache-name }}-downloads
#    - name: Bulid
#      run: |
#        export BR_BOUFFALO_OVERLAY_PATH=$(pwd)/buildroot_bouffalo
#        cd buildroot
#        make BR2_EXTERNAL=$BR_BOUFFALO_OVERLAY_PATH ${{ matrix.target }}
#        make
#        make sdk
#        make ccache-stats
#    - name: Pack
#      run: |
#        cd ${{ github.workspace }}/buildroot/output/images/
#        ls -lah
#        if [ -f sdcard.img ]; then
#            xz -z sdcard.img
#            mv sdcard.img.xz sdcard-${{ matrix.target }}.img.xz
#        fi
#        if [ -f Image ]; then
#            lz4 -9 -f Image Image-${{ matrix.target }}.lz4
#        fi
#        echo "PACKAGE=${{ github.workspace }}/buildroot/output/images/sdcard-${{ matrix.target }}.img.xz" >> $GITHUB_ENV
#        echo "KERNEL=${{ github.workspace }}/buildroot/output/images/Image-${{ matrix.target }}.lz4" >> $GITHUB_ENV
#        echo "DTB=${{ github.workspace }}/buildroot/output/images/bl808-*.dtb" >> $GITHUB_ENV
#        echo "OPENSBI=${{ github.workspace }}/buildroot/output/images/fw_jump.bin" >> $GITHUB_ENV
#        echo "LOWLOAD=${{ github.workspace }}/buildroot/output/images/*_lowload_bl808_*.bin" >> $GITHUB_ENV
#        echo "WHOLEBINOX=${{ github.workspace }}/buildroot/output/images/pine64-ox64-firmware.bin" >> $GITHUB_ENV
#        echo "WHOLEBINM1=${{ github.workspace }}/buildroot/output/images/sispeed-m1s-firmware.bin" >> $GITHUB_ENV
#        echo "BRSDK=${{ github.workspace }}/buildroot/output/images/riscv*.tar.gz" >> $GITHUB_ENV
#    - name: Upload package
#      uses: actions/upload-artifact@master
#      with:
#        name: build artifacts
#        path: |
#          ${{env.PACKAGE}}
#          ${{env.KERNEL}}
#          ${{env.DTB}}
#          ${{env.OPENSBI}}
#          ${{env.LOWLOAD}}
#          ${{env.WHOLEBINOX}}
#          ${{env.WHOLEBINM1}}
#    - name: Upload sdk
#      if: matrix.target == 'pine64_ox64_full_defconfig'
#      uses: actions/upload-artifact@master
#      with:
#        name: buildroot-sdk
#        path: |
#          ${{env.BRSDK}}
#
#  createimages:
#    strategy:
#      fail-fast: true
#      matrix:
#        target: [ pine64_ox64_defconfig, pine64_ox64_full_defconfig ]
#    runs-on: ubuntu-22.04
#    needs: [buildroot]
#    steps:
#    - name: install dependencies
#      run: |
#        sudo apt-get install -y python3
#    - name: Checkout OpenBouffalo Buildroot
#      uses: actions/checkout@v3
#      with:
#        path: buildroot_bouffalo
#    - name: Download build files
#      uses: actions/download-artifact@v3
#      with:
#        name: build artifacts
#        path: ${{ github.workspace }}/build
#    - name: Create images
#      run: |
#        cd ${{ github.workspace }}/build
#        ls -lah 
#        mv Image-${{ matrix.target }}.lz4 Image.lz4
#        mkdir firmware
#        cp *_lowload_bl808_*.bin firmware/
#        cp pine64-ox64-firmware.bin firmware/
#        cp sispeed-m1s-firmware.bin firmware/
#        cp sdcard-${{ matrix.target }}.img.xz firmware/
#        tar -czvf bl808-linux-${{ matrix.target }}.tar.gz firmware
#        echo "FIRMWARE=${{ github.workspace }}/build/bl808-linux-${{ matrix.target }}.tar.gz" >> $GITHUB_ENV
#    - name: Upload Firmware
#      uses: actions/upload-artifact@master
#      with:
#        name: linux-buildroot-${{ matrix.target }}
#        path: |
#          ${{env.FIRMWARE}}        
#
#  release:
#    if: startsWith(github.ref, 'refs/tags/')
#    runs-on: ubuntu-22.04
#    needs: [createimages]
#    permissions: write-all
#    steps:
#      - name: download firmware
#        uses: actions/download-artifact@v3
#      - name: Create images
#        run: |
#          ls -lah
#          ls -lah linux-buildroot-*/*.tar.gz
#          ls -lah buildroot-sdk/*.tar.gz
#      - name: publish artifacts
#        uses: softprops/action-gh-release@v1
#        with:
#          append_body: true
#          files: |
#            linux-buildroot-*/*.tar.gz
#            buildroot-sdk/*.tar.gz
#
#
