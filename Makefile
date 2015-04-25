ARCHS = armv7 arm64
TARGET = iphone:clang::8.0
include theos/makefiles/common.mk

TWEAK_NAME = PullBulletin
PullBulletin_FILES = Tweak.xm
PullBulletin_FRAMEWORKS = UIKit
PullBulletin_CFLAGS += -I ../AASpringRefresh/AASpringRefresh
PullBulletin_LDFLAGS += -L ../AASpringRefresh/AASpringRefreshDemo/build/Release-iphoneos
PullBulletin_LIBRARIES = AASpringRefresh

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
