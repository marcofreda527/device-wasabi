#!/bin/bash

# Copyright (C) 2010 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

DEVICE=wasabi
COMMON=common
MANUFACTURER=qcom

if [[ -z "${ANDROIDFS_DIR}" && -d ../../../backup-${DEVICE}/system ]]; then
    ANDROIDFS_DIR=../../../backup-${DEVICE}
fi

if [[ -z "${ANDROIDFS_DIR}" ]]; then
    echo Pulling files from device
    DEVICE_BUILD_ID=`adb shell cat /system/build.prop | grep ro.build.id | sed -e 's/ro.build.id=//' | tr -d '\n\r'`
else
    echo Pulling files from ${ANDROIDFS_DIR}
    DEVICE_BUILD_ID=`cat ${ANDROIDFS_DIR}/system/build.prop | grep ro.build.id | sed -e 's/ro.build.id=//' | tr -d '\n\r'`
fi

case "$DEVICE_BUILD_ID" in
IMM76D*)
  FIRMWARE=ICS
  echo Found ICS firmware with build ID $DEVICE_BUILD_ID >&2
  ;;
*)
  FIRMWARE=unknown
  echo Found unknown firmware with build ID $DEVICE_BUILD_ID >&2
  echo Please download a compatible backup-${DEVICE} directory.
  echo Check the ${DEVICE} intranet page 4 information on how to get one.
  exit -1
  ;;
esac

if [[ ! -d ../../../backup-${DEVICE}/system  && -z "${ANDROIDFS_DIR}" ]]; then
    echo Backing up system partition to backup-${DEVICE}
    mkdir -p ../../../backup-${DEVICE} &&
    adb pull /system ../../../backup-${DEVICE}/system
    ANDROIDFS_DIR=../../../backup-${DEVICE}/system
fi

ABS_ANDROIDFS_DIR=${ANDROIDFS_DIR#\.\./\.\./\.\./}

BASE_PROPRIETARY_COMMON_DIR=vendor/$MANUFACTURER/$COMMON/proprietary
PROPRIETARY_DEVICE_DIR=../../../vendor/$MANUFACTURER/$DEVICE/proprietary
PROPRIETARY_COMMON_DIR=../../../$BASE_PROPRIETARY_COMMON_DIR

mkdir -p $PROPRIETARY_DEVICE_DIR

for NAME in hw etc egl modules
do
    mkdir -p $PROPRIETARY_COMMON_DIR/$NAME
done

COMMON_BLOBS_LIST=../../../vendor/$MANUFACTURER/$COMMON/vendor-blobs.mk

(cat << EOF) | sed s/__COMMON__/$COMMON/g | sed s/__MANUFACTURER__/$MANUFACTURER/g > $COMMON_BLOBS_LIST
# Copyright (C) 2010 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Prebuilt libraries that are needed to build open-source libraries
PRODUCT_COPY_FILES := device/sample/etc/apns-full-conf.xml:system/etc/apns-conf.xml

# All the blobs
PRODUCT_COPY_FILES += \\
EOF

# copy_file
# pull file from the device and adds the file to the list of blobs
#
# $1 = src name
# $2 = dst name
# $3 = directory path on device
# $4 = directory name in $PROPRIETARY_COMMON_DIR
copy_file()
{
    echo Pulling \"$1\" ${ANDROIDFS_DIR}/$3/$1 $PROPRIETARY_COMMON_DIR/$4/$2
    if [[ -z "${ANDROIDFS_DIR}" ]]; then
	NAME=$1
        adb pull /$3/$1 $PROPRIETARY_COMMON_DIR/$4/$2
    else
	NAME=`basename ${ANDROIDFS_DIR}/$3/$1`
	rm -f $PROPRIETARY_DEVICE_DIR/$4/$NAME
           # Hint: Uncomment the next line to populate a fresh ANDROIDFS_DIR
           #       (TODO: Make this a command-line option or something.)
           # adb pull /$3/$1 ${ANDROIDFS_DIR}/$3/$1
        cp ${ANDROIDFS_DIR}/$3/$NAME $PROPRIETARY_COMMON_DIR/$4/$NAME
    fi
    echo check \"$1\" ${ANDROIDFS_DIR}/$3/$1 $PROPRIETARY_COMMON_DIR/$4/$2
    if [[ -f $PROPRIETARY_COMMON_DIR/$4/$NAME ]]; then
        echo   $BASE_PROPRIETARY_COMMON_DIR/$4/$NAME:$3/$NAME \\ >> $COMMON_BLOBS_LIST
    else
        echo Failed to pull $1. Giving up.
        exit -1
    fi
}

# copy_files
# pulls a list of files from the device and adds the files to the list of blobs
#
# $1 = list of files
# $2 = directory path on device
# $3 = directory name in $PROPRIETARY_COMMON_DIR
copy_files()
{
    for NAME in $1
    do
        copy_file "$NAME" "$NAME" "$2" "$3"
    done
}

# copy_local_files
# puts files in this directory on the list of blobs to install
#
# $1 = list of files
# $2 = directory path on device
# $3 = local directory path
copy_local_files()
{
    for NAME in $1
    do
        echo Adding \"$NAME\"
        echo device/$MANUFACTURER/$DEVICE/$3/$NAME:$2/$NAME \\ >> $COMMON_BLOBS_LIST
    done
}

COMMON_LIBS="
	liboverlay.so
	libsc-a2xx.so
	libchromium_net.so
	libalsa-intf.so
	libaudcal.so
	libdiag.so
	libqmi.so
	libsrsprocessing.so
	libmplmpu.so
	libqmiservices.so
	libtime_genoff.so
	libmllite.so
	libhardware_legacy.so
	libdsutils.so
	libUw.so
	liboemcamera.so
	libcamera_client.so
	libmmcamera_faceproc.so
	libmmcamera_frameproc.so
	libC2D2.so
	libOpenVG.so
	libxml2.so
	libidl.so
	libhwui.so
	lib*drmcore.so
	libQcomUI.so
	libmemalloc.so
	libacdbloader.so
	libquipc_os_api.so
	libakmd.so
	libcurl.so
	libhardware.so
	libgsl.so
	libloc_api_v02.so
	libmmjpeg.so
	libnetmgr.so
	libgenlock.so
	libwifiscanner.so
	libinvensense_hal.so
	libsensor1.so
	libcaveapi.so
	libbluedroid.so
	libbluetoothd.so
	libbluetooth.so
	libbtio.so
	libqmi_csi.so
	libloc_eng.so
	libtilerenderer.so
	libqc-opt.so
	libmm-abl.so
	libgemini.so
	libqmi_cci.so
	libqmi_encdec.so
	libbson.so
	libloc_adapter.so
	libgps.utils.so
	libqmi_common_so.so
	libcneutils.so
	libmm-abl-oem.so
	libminzip_ftm.so
	libquipc_ulp_adapter.so
	libaudioparameter.so
	libmlplatform.so
	libimage-jpeg-enc-omx-comp.so
	libminui_ftm.so
	libmmstillomx.so
	libimage-omx-common.so
	libxml.so
	libcneqmiutils.so
	libtilerenderer.so
	libstagefrighthw.so
	libmm-omxcore.so
	libOmxVdec.so
	libOmxVenc.so
	libloc_adapter.so
	libloc_api_v02.so
	libloc_eng.so
	libloc_ext.so
	liblocSDK_2.2.so
	libril-qc-qmi-1.so
	libril-qcril-hook-oem.so
	libril.so
	libreference-ril.so
	libQSEEComAPI.so
	libdsi_netctrl.so
	libqdi.so
	libqdp.so
        libmedia.so
	"

copy_files "$COMMON_LIBS" "system/lib" ""

COMMON_BINS="
	akmd8962_new
	bridgemgrd
	ext4check.sh
	fm_qsoc_patches
	fmconfig
	hci_qcomm_init
	netmgrd
	port-bridge
	proximity.init
	qmiproxy
	qmuxd
	rild
	radish
	rmt_storage
	log
	ftmdaemon-oem
	app6939
	mm-qcamera-daemon
	copypartnerapp
	cnd
	wiperiface
	ATFWD-daemon
	mm-pp-daemon
	getlogtofile
	quipc_igsn
	quipc_main
	"

copy_files "$COMMON_BINS" "system/bin" ""

COMMON_HW="
	alsa.msm8960.so
	audio.primary.msm8960.so
	camera.msm8960.so
	gralloc.msm8960.so
	lights.msm8960.so
	sensors.msm8960.so
	copybit.msm8960.so
	audio_policy.msm8960.so
	"

copy_files "$COMMON_HW" "system/lib/hw" "hw"

COMMON_EGL="
	eglsubAndroid.so
	libEGL_adreno200.so
	libGLES_android.so
	libGLESv1_CM_adreno200.so
	libGLESv2_adreno200.so
	libGLESv2S3D_adreno200.so
	libq3dtools_adreno200.so
	"

copy_files "$COMMON_EGL" "system/lib/egl" "egl"

COMMON_WIFI="
	ansi_cprng.ko
	bluetooth-power.ko
	dma_test.ko
	eeprom_93cx6.ko
	evbug.ko
	gspca_main.ko
	ks8851.ko
	lcd.ko
	mmc_test.ko
	msm-buspm-dev.ko
	qce40.ko
	qcedev.ko
	qcrypto.ko
	radio-iris-transport.ko
	reset_modem.ko
	scsi_wait_scan.ko
	spidev.ko
	wlan.ko
	*_krait_oc.ko
	"

copy_files "$COMMON_WIFI" "system/lib/modules" "modules"

COMMON_ETC="
	init.ct_fmc.sh
	init.goldfish.sh
	init.qcom.bt.sh
	init.qcom.coex.sh
	init.qcom.fm.sh
	init.qcom.post_boot.sh
	init.qcom.wifi.sh
	init.wlanprop.sh
	gps.conf
	"

copy_files "$COMMON_ETC" "system/etc" "etc"

(cat << EOF) | sed s/__DEVICE__/$DEVICE/g | sed s/__MANUFACTURER__/$MANUFACTURER/g > ../../../vendor/$MANUFACTURER/$DEVICE/$DEVICE-vendor-blobs.mk
# Copyright (C) 2010 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

LOCAL_PATH := ${ABS_ANDROIDFS_DIR}/system/etc/firmware

PRODUCT_COPY_FILES := \
    \$(LOCAL_PATH)/a225p5_pm4.fw:system/etc/firmware/a225p5_pm4.fw \\
    \$(LOCAL_PATH)/a225_pfp.fw:system/etc/firmware/a225_pfp.fw \\
    \$(LOCAL_PATH)/a225_pm4.fw:system/etc/firmware/a225_pm4.fw \\
    \$(LOCAL_PATH)/a300_pfp.fw:system/etc/firmware/a300_pfp.fw \\
    \$(LOCAL_PATH)/a300_pm4.fw:system/etc/firmware/a300_pm4.fw \\
    \$(LOCAL_PATH)/cyttsp_8960_cdp.hex:system/etc/firmware/cyttsp_8960_cdp.hex \\
    \$(LOCAL_PATH)/leia_pfp_470.fw:system/etc/firmware/leia_pfp_470.fw \\
    \$(LOCAL_PATH)/leia_pm4_470.fw:system/etc/firmware/leia_pm4_470.fw \\
    \$(LOCAL_PATH)/modem.b00:system/etc/firmware/modem.b00 \\
    \$(LOCAL_PATH)/modem.b01:system/etc/firmware/modem.b01 \\
    \$(LOCAL_PATH)/modem.b02:system/etc/firmware/modem.b02 \\
    \$(LOCAL_PATH)/modem.b03:system/etc/firmware/modem.b03 \\
    \$(LOCAL_PATH)/modem.b04:system/etc/firmware/modem.b04 \\
    \$(LOCAL_PATH)/modem.b06:system/etc/firmware/modem.b06 \\
    \$(LOCAL_PATH)/modem.b07:system/etc/firmware/modem.b07 \\
    \$(LOCAL_PATH)/modem_f1.b00:system/etc/firmware/modem_f1.b00 \\
    \$(LOCAL_PATH)/modem_f1.b01:system/etc/firmware/modem_f1.b01 \\
    \$(LOCAL_PATH)/modem_f1.b02:system/etc/firmware/modem_f1.b02 \\
    \$(LOCAL_PATH)/modem_f1.b03:system/etc/firmware/modem_f1.b03 \\
    \$(LOCAL_PATH)/modem_f1.b04:system/etc/firmware/modem_f1.b04 \\
    \$(LOCAL_PATH)/modem_f1.b05:system/etc/firmware/modem_f1.b05 \\
    \$(LOCAL_PATH)/modem_f1.b06:system/etc/firmware/modem_f1.b06 \\
    \$(LOCAL_PATH)/modem_f1.b07:system/etc/firmware/modem_f1.b07 \\
    \$(LOCAL_PATH)/modem_f1.b08:system/etc/firmware/modem_f1.b08 \\
    \$(LOCAL_PATH)/modem_f1.b09:system/etc/firmware/modem_f1.b09 \\
    \$(LOCAL_PATH)/modem_f1.b10:system/etc/firmware/modem_f1.b10 \\
    \$(LOCAL_PATH)/modem_f1.b13:system/etc/firmware/modem_f1.b13 \\
    \$(LOCAL_PATH)/modem_f1.b14:system/etc/firmware/modem_f1.b14 \\
    \$(LOCAL_PATH)/modem_f1.b21:system/etc/firmware/modem_f1.b21 \\
    \$(LOCAL_PATH)/modem_f1.b22:system/etc/firmware/modem_f1.b22 \\
    \$(LOCAL_PATH)/modem_f1.b23:system/etc/firmware/modem_f1.b23 \\
    \$(LOCAL_PATH)/modem_f1.b25:system/etc/firmware/modem_f1.b25 \\
    \$(LOCAL_PATH)/modem_f1.b26:system/etc/firmware/modem_f1.b26 \\
    \$(LOCAL_PATH)/modem_f1.b29:system/etc/firmware/modem_f1.b29 \\
    \$(LOCAL_PATH)/modem_f1.fli:system/etc/firmware/modem_f1.fli \\
    \$(LOCAL_PATH)/modem_f1.mdt:system/etc/firmware/modem_f1.mdt \\
    \$(LOCAL_PATH)/modem_f2.b00:system/etc/firmware/modem_f2.b00 \\
    \$(LOCAL_PATH)/modem_f2.b01:system/etc/firmware/modem_f2.b01 \\
    \$(LOCAL_PATH)/modem_f2.b02:system/etc/firmware/modem_f2.b02 \\
    \$(LOCAL_PATH)/modem_f2.b03:system/etc/firmware/modem_f2.b03 \\
    \$(LOCAL_PATH)/modem_f2.b04:system/etc/firmware/modem_f2.b04 \\
    \$(LOCAL_PATH)/modem_f2.b05:system/etc/firmware/modem_f2.b05 \\
    \$(LOCAL_PATH)/modem_f2.b06:system/etc/firmware/modem_f2.b06 \\
    \$(LOCAL_PATH)/modem_f2.b07:system/etc/firmware/modem_f2.b07 \\
    \$(LOCAL_PATH)/modem_f2.b08:system/etc/firmware/modem_f2.b08 \\
    \$(LOCAL_PATH)/modem_f2.b09:system/etc/firmware/modem_f2.b09 \\
    \$(LOCAL_PATH)/modem_f2.b10:system/etc/firmware/modem_f2.b10 \\
    \$(LOCAL_PATH)/modem_f2.b13:system/etc/firmware/modem_f2.b13 \\
    \$(LOCAL_PATH)/modem_f2.b14:system/etc/firmware/modem_f2.b14 \\
    \$(LOCAL_PATH)/modem_f2.b21:system/etc/firmware/modem_f2.b21 \\
    \$(LOCAL_PATH)/modem_f2.b22:system/etc/firmware/modem_f2.b22 \\
    \$(LOCAL_PATH)/modem_f2.b23:system/etc/firmware/modem_f2.b23 \\
    \$(LOCAL_PATH)/modem_f2.b25:system/etc/firmware/modem_f2.b25 \\
    \$(LOCAL_PATH)/modem_f2.b26:system/etc/firmware/modem_f2.b26 \\
    \$(LOCAL_PATH)/modem_f2.b29:system/etc/firmware/modem_f2.b29 \\
    \$(LOCAL_PATH)/modem_f2.fli:system/etc/firmware/modem_f2.fli \\
    \$(LOCAL_PATH)/modem_f2.mdt:system/etc/firmware/modem_f2.mdt \\
    \$(LOCAL_PATH)/modem_fw.b00:system/etc/firmware/modem_fw.b00 \\
    \$(LOCAL_PATH)/modem_fw.b01:system/etc/firmware/modem_fw.b01 \\
    \$(LOCAL_PATH)/modem_fw.b02:system/etc/firmware/modem_fw.b02 \\
    \$(LOCAL_PATH)/modem_fw.b03:system/etc/firmware/modem_fw.b03 \\
    \$(LOCAL_PATH)/modem_fw.b04:system/etc/firmware/modem_fw.b04 \\
    \$(LOCAL_PATH)/modem_fw.b05:system/etc/firmware/modem_fw.b05 \\
    \$(LOCAL_PATH)/modem_fw.b06:system/etc/firmware/modem_fw.b06 \\
    \$(LOCAL_PATH)/modem_fw.b07:system/etc/firmware/modem_fw.b07 \\
    \$(LOCAL_PATH)/modem_fw.b08:system/etc/firmware/modem_fw.b08 \\
    \$(LOCAL_PATH)/modem_fw.b09:system/etc/firmware/modem_fw.b09 \\
    \$(LOCAL_PATH)/modem_fw.b10:system/etc/firmware/modem_fw.b10 \\
    \$(LOCAL_PATH)/modem_fw.b13:system/etc/firmware/modem_fw.b13 \\
    \$(LOCAL_PATH)/modem_fw.b14:system/etc/firmware/modem_fw.b14 \\
    \$(LOCAL_PATH)/modem_fw.b21:system/etc/firmware/modem_fw.b21 \\
    \$(LOCAL_PATH)/modem_fw.b22:system/etc/firmware/modem_fw.b22 \\
    \$(LOCAL_PATH)/modem_fw.b23:system/etc/firmware/modem_fw.b23 \\
    \$(LOCAL_PATH)/modem_fw.b25:system/etc/firmware/modem_fw.b25 \\
    \$(LOCAL_PATH)/modem_fw.b26:system/etc/firmware/modem_fw.b26 \\
    \$(LOCAL_PATH)/modem_fw.b29:system/etc/firmware/modem_fw.b29 \\
    \$(LOCAL_PATH)/modem_fw.fli:system/etc/firmware/modem_fw.fli \\
    \$(LOCAL_PATH)/modem_fw.mdt:system/etc/firmware/modem_fw.mdt \\
    \$(LOCAL_PATH)/modem.mdt:system/etc/firmware/modem.mdt \\
    \$(LOCAL_PATH)/PR1183396_s2202_32313037.img:/system/etc/firmware/PR1183396_s2202_32313037.img \\
    \$(LOCAL_PATH)/q6.b00:/system/etc/firmware/q6.b00 \\
    \$(LOCAL_PATH)/q6.b01:/system/etc/firmware/q6.b01 \\
    \$(LOCAL_PATH)/q6.b03:/system/etc/firmware/q6.b03 \\
    \$(LOCAL_PATH)/q6.b04:/system/etc/firmware/q6.b04 \\
    \$(LOCAL_PATH)/q6.b05:/system/etc/firmware/q6.b05 \\
    \$(LOCAL_PATH)/q6.b06:/system/etc/firmware/q6.b06 \\
    \$(LOCAL_PATH)/q6.mdt:/system/etc/firmware/q6.mdt \\
    \$(LOCAL_PATH)/tzapps.b00:/system/etc/firmware/tzapps.b00 \\
    \$(LOCAL_PATH)/tzapps.b01:/system/etc/firmware/tzapps.b01 \\
    \$(LOCAL_PATH)/tzapps.b02:/system/etc/firmware/tzapps.b02 \\
    \$(LOCAL_PATH)/tzapps.b03:/system/etc/firmware/tzapps.b03 \\
    \$(LOCAL_PATH)/tzapps.mdt:/system/etc/firmware/tzapps.mdt \\
    \$(LOCAL_PATH)/vidc_1080p.fw:/system/etc/firmware/vidc_1080p.fw \\
    \$(LOCAL_PATH)/vidc.b00:/system/etc/firmware/vidc.b00 \\
    \$(LOCAL_PATH)/vidc.b01:/system/etc/firmware/vidc.b01 \\
    \$(LOCAL_PATH)/vidc.b02:/system/etc/firmware/vidc.b02 \\
    \$(LOCAL_PATH)/vidc.b03:/system/etc/firmware/vidc.b03 \\
    \$(LOCAL_PATH)/vidcfw.elf:/system/etc/firmware/vidcfw.elf \\
    \$(LOCAL_PATH)/vidc.mdt:/system/etc/firmware/vidc.mdt \\
    \$(LOCAL_PATH)/wcnss.b00:/system/etc/firmware/wcnss.b00 \\
    \$(LOCAL_PATH)/wcnss.b01:/system/etc/firmware/wcnss.b01 \\
    \$(LOCAL_PATH)/wcnss.b02:/system/etc/firmware/wcnss.b02 \\
    \$(LOCAL_PATH)/wcnss.b04:/system/etc/firmware/wcnss.b04 \\
    \$(LOCAL_PATH)/wcnss.mdt:/system/etc/firmware/wcnss.mdt \\
    \$(LOCAL_PATH)/wlan/prima/WCNSS_cfg.dat:/system/etc/firmware/wlan/prima/WCNSS_cfg.dat \\
    \$(LOCAL_PATH)/wlan/prima/WCNSS_qcom_cfg.ini:/system/etc/firmware/wlan/prima/WCNSS_qcom_cfg.ini \\
    \$(LOCAL_PATH)/wlan/prima/WCNSS_qcom_wlan_nv.bin:/system/etc/firmware/wlan/prima/WCNSS_qcom_wlan_nv.bin

LOCAL_PATH := ${ABS_ANDROIDFS_DIR}/system/etc/snd_soc_msm
PRODUCT_COPY_FILES += \
    \$(LOCAL_PATH)/Voice_Call:/system/etc/snd_soc_msm/Voice_Call \\
    \$(LOCAL_PATH)/HiFi:/system/etc/snd_soc_msm/HiFi \\
    \$(LOCAL_PATH)/HiFi_Rec:/system/etc/snd_soc_msm/HiFi_Rec \\
    \$(LOCAL_PATH)/UL_DL_REC_2x:/system/etc/snd_soc_msm/UL_DL_REC_2x \\
    \$(LOCAL_PATH)/FM_A2DP_REC_2x:/system/etc/snd_soc_msm/FM_A2DP_REC_2x \\
    \$(LOCAL_PATH)/Voice_Call_2x:/system/etc/snd_soc_msm/Voice_Call_2x \\
    \$(LOCAL_PATH)/FM_A2DP_REC:/system/etc/snd_soc_msm/FM_A2DP_REC \\
    \$(LOCAL_PATH)/HiFi_Rec_2x:/system/etc/snd_soc_msm/HiFi_Rec_2x \\
    \$(LOCAL_PATH)/HiFi_2x:/system/etc/snd_soc_msm/HiFi_2x \\
    \$(LOCAL_PATH)/Voice_Call_IP_2x:/system/etc/snd_soc_msm/Voice_Call_IP_2x\\
    \$(LOCAL_PATH)/HiFi_Low_Power:/system/etc/snd_soc_msm/HiFi_Low_Power \\
    \$(LOCAL_PATH)/DL_REC:/system/etc/snd_soc_msm/DL_REC \\
    \$(LOCAL_PATH)/HiFi_Low_Power_2x:/system/etc/snd_soc_msm/HiFi_Low_Power_2x \\
    \$(LOCAL_PATH)/snd_soc_msm_2x:/system/etc/snd_soc_msm/snd_soc_msm_2x \\
    \$(LOCAL_PATH)/FM_REC_2x:/system/etc/snd_soc_msm/FM_REC_2x \\
    \$(LOCAL_PATH)/DL_REC_2x:/system/etc/snd_soc_msm/DL_REC_2x \\
    \$(LOCAL_PATH)/FM_Digital_Radio:/system/etc/snd_soc_msm/FM_Digital_Radio \\
    \$(LOCAL_PATH)/snd_soc_msm:/system/etc/snd_soc_msm/snd_soc_msm \\
    \$(LOCAL_PATH)/FM_Digital_Radio_2x:/system/etc/snd_soc_msm/FM_Digital_Radio_2x \\
    \$(LOCAL_PATH)/Voice_Call_IP:/system/etc/snd_soc_msm/Voice_Call_IP \\
    \$(LOCAL_PATH)/UL_DL_REC:/system/etc/snd_soc_msm/UL_DL_REC \\
    \$(LOCAL_PATH)/FM_REC:/system/etc/snd_soc_msm/FM_REC
EOF

