# Generic IOC Makefile

TOP = ../..
include $(TOP)/configure/CONFIG

PROD_IOC = ioc
DBD += ioc.dbd
ioc_DBD += base.dbd

# add in the dbds collected by ibek during container build
ioc_DBD += $(shell cat /epics/support/configure/dbd_list)

ioc_SRCS += ioc_registerRecordDeviceDriver.cpp

# add in the libs collected by ibek during container build (in reverse order)
ioc_LIBS += $(shell tac /epics/support/configure/lib_list)

ioc_LIBS += $(EPICS_BASE_IOC_LIBS)
ioc_SRCS += iocMain.cpp

include $(TOP)/configure/RULES
