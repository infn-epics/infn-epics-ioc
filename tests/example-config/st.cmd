# Example hand coded IOC startup script for example-config
cd "/epics/ioc"

epicsEnvSet "EPICS_CA_MAX_ARRAY_BYTES", '6000000'

dbLoadDatabase "dbd/ioc.dbd"
ioc_registerRecordDeviceDriver(pdbbase)

dbLoadRecords("config/calc.db")
dbLoadRecords("/tmp/ioc.db")

iocInit()
