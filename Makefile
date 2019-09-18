ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = PhotoCtrl
PhotoCtrl_FILES = Tweak.xm
#PhotoCtrl_CFLAGS = -fobjc-arc
PhotoCtrl_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 MobileSlideShow"
