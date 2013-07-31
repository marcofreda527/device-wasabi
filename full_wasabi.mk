$(call inherit-product, device/qcom/common/common.mk)
PRODUCT_COPY_FILES := \
  device/qcom/wasabi/touchscreen.idc:system/usr/idc/atmel-touchscreen.idc \
  device/qcom/wasabi/touchscreen.idc:system/usr/idc/syna-touchscreen.idc \
  device/qcom/msm8960/wpa_supplicant.conf:system/etc/wifi/wpa_supplicant.conf \
  device/qcom/wasabi/media_profiles.xml:system/etc/media_profiles.xml

$(call inherit-product-if-exists, vendor/qcom/wasabi/wasabi-vendor-blobs.mk)
$(call inherit-product-if-exists, vendor/qcom/common/vendor-blobs.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full.mk)

PRODUCT_PROPERTY_OVERRIDES += \
  rild.libpath=/system/lib/libril-qc-qmi-1.so \
  rild.libargs=-d/dev/smd0 \
  ro.qualcomm.bt.hci_transport=smd \
  ro.moz.cam.0.sensor_offset=180 \
  ro.use_data_netmgrd=true \
  ro.moz.ril.simstate_extra_field=true \
  ro.moz.ril.emergency_by_default=true \
  persist.audio.handset.mic=analog

# Discard inherited values and use our own instead.
PRODUCT_NAME := full_wasabi
PRODUCT_DEVICE := wasabi
PRODUCT_BRAND := qcom
PRODUCT_MANUFACTURER := qcom
PRODUCT_MODEL := wasabi

PRODUCT_DEFAULT_PROPERTY_OVERRIDES := \
  persist.usb.serialno=$(PRODUCT_NAME)
