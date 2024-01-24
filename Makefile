TOP = ../..
include $(TOP)/configure/CONFIG

PROD_IOC = ioc
DBD += ioc.dbd
ioc_DBD += base.dbd
ioc_DBD += devIocStats.dbd
ioc_DBD += asyn.dbd
ioc_DBD += busySupport.dbd
## TODO add required dbds

ioc_SRCS += ioc_registerRecordDeviceDriver.cpp

## TODO add required libs
ioc_LIBS += busy
ioc_LIBS += asyn
ioc_LIBS += devIocStats
ioc_LIBS += $(EPICS_BASE_IOC_LIBS)
ioc_SRCS += iocMain.cpp

## TODO add system libraries
# ioc_SYS_LIBS += aravis-0.8

include $(TOP)/configure/RULES
