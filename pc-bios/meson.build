bzip2 = find_program('bzip2')

install_blobs = 'INSTALL_BLOBS' in config_host
if 'DECOMPRESS_EDK2_BLOBS' in config_host
  fds = [
    'edk2-aarch64-code.fd',
    'edk2-arm-code.fd',
    'edk2-arm-vars.fd',
    'edk2-i386-code.fd',
    'edk2-i386-secure-code.fd',
    'edk2-i386-vars.fd',
    'edk2-x86_64-code.fd',
    'edk2-x86_64-secure-code.fd',
  ]

  foreach f : fds
    custom_target(f,
                  output: f,
                  input: '@0@.bz2'.format(f),
                  capture: true,
                  install: install_blobs,
                  install_dir: config_host['qemu_datadir'],
                  command: [ bzip2, '-dc', '@INPUT0@' ])
  endforeach
endif

blobs = files(
  'QEMU,cgthree.bin',
  'QEMU,tcx.bin',
  'bamboo.dtb',
  'bios-256k.bin',
  'bios.bin',
  'bios-microvm.bin',
  'canyonlands.dtb',
  'edk2-licenses.txt',
  'efi-e1000.rom',
  'efi-e1000e.rom',
  'efi-eepro100.rom',
  'efi-ne2k_pci.rom',
  'efi-pcnet.rom',
  'efi-rtl8139.rom',
  'efi-virtio.rom',
  'efi-vmxnet3.rom',
  'hppa-firmware.img',
  'kvmvapic.bin',
  'linuxboot.bin',
  'linuxboot_dma.bin',
  'multiboot.bin',
  'openbios-ppc',
  'openbios-sparc32',
  'openbios-sparc64',
  'opensbi-riscv32-sifive_u-fw_jump.bin',
  'opensbi-riscv32-virt-fw_jump.bin',
  'opensbi-riscv64-sifive_u-fw_jump.bin',
  'opensbi-riscv64-virt-fw_jump.bin',
  'palcode-clipper',
  'petalogix-ml605.dtb',
  'petalogix-s3adsp1800.dtb',
  'pvh.bin',
  'pxe-e1000.rom',
  'pxe-eepro100.rom',
  'pxe-ne2k_pci.rom',
  'pxe-pcnet.rom',
  'pxe-rtl8139.rom',
  'pxe-virtio.rom',
  'qemu-nsis.bmp',
  'qemu_vga.ndrv',
  's390-ccw.img',
  's390-netboot.img',
  'sgabios.bin',
  'skiboot.lid',
  'slof.bin',
  'u-boot-sam460-20100605.bin',
  'u-boot.e500',
  'vgabios-ati.bin',
  'vgabios-bochs-display.bin',
  'vgabios-cirrus.bin',
  'vgabios-qxl.bin',
  'vgabios-ramfb.bin',
  'vgabios-stdvga.bin',
  'vgabios-virtio.bin',
  'vgabios-vmware.bin',
)

if install_blobs
  install_data(blobs, install_dir: config_host['qemu_datadir'])
endif

subdir('descriptors')
