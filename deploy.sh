ROOTFS=/media/rootfs
BOOT=/media/boot
BUILD_DIR=build/tmp-angstrom_v2013_06-eglibc/deploy/images/beaglebone
pflag=
pval=
cflag=
#expect to partitions of an SD-card

create_flasher_image()
{
	if [[ ! -d $ROOTFS ]]; then
		echo "no rootfs mounted";
		exit
	fi
	if [[ ! -d $BOOT ]]; then
		echo "no boot partition mounted";
		exit
	fi
	FLASHER_IMAGE=$(find ${BUILD_DIR} -name "flasher-image-vaf*.tar.xz")
	echo "Copying ${FLASHER_IMAGE} to $ROOTFS"
	sudo rm -r ${ROOTFS}/*
	sudo tar -xf ${BUILD_DIR}/flasher-image-vaf-beaglebone.tar.xz -C ${ROOTFS}

	echo "Copying .dtb files and kernel"
	sudo cp ~/Documents/projects/pem2/images/BBB_flasher_image/boot/uImage_vaf ${ROOTFS}/boot
	sudo ln -sf /boot/uImage_vaf ${ROOTFS}/boot/uImage

	echo "Copying image to flash"
		sudo mkdir ${BOOT}/linux
		sudo cp ${BUILD_DIR}/console-image-vaf-beaglebone.tar.xz ${BOOT}/linux

	echo "Coyping bootloader MLO and uEnvt"
	sudo cp ~/Documents/projects/pem2/images/BBB_flasher_image/boot/MLO ${BOOT}
	sudo cp ~/Documents/projects/pem2/images/BBB_flasher_image/boot/u-boot.img ${BOOT}
	sudo cp ~/Documents/projects/pem2/images/BBB_flasher_image/boot/uEnv.txt ${BOOT}
}

prepare_sdcard()
{
	echo "preparing drive: $1"
	fdisk -l $1
	read -p "Press [Enter] to continue..."
	umount ${1}1
	umount ${1}2
	{ 
		echo o
		echo n
		echo p
		echo 1
		echo 
		echo 100000
		echo n
		echo p
		echo 2
		echo 
		echo 400000
		echo w
	}	| fdisk $1
	sync
	mkfs.msdos ${1}1 -n "boot"
	mkfs.ext2 ${1}2 -L "rootfs"
}

while getopts cp: arg; do
  case "${arg}" in
  p)
 	    pval="$OPTARG"
			pflag=1
      ;;
  c)
			cflag=1
      ;;
	\?)	
			echo "invalid option -$OPTARG" >&2
			;;
  esac
done

if [ ! -z "$pflag" ]; then
	prepare_sdcard $pval
fi
if [ ! -z "$cflag" ]; then
	create_flasher_image
fi

shift $((OPTIND-1))


