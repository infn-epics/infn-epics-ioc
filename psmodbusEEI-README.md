# psmodbusEEI IOC Configuration

This configuration file is used to generate an IBEK-based IOC for EEI Power Supply control via Modbus TCP/IP.

## Overview

This IOC provides EPICS control and monitoring for EEI Power Supplies using Modbus protocol over TCP/IP.

## Configuration Structure

- **iocname**: Unique IOC identifier
- **iocprefix**: EPICS PV prefix for all records
- **devtype**: psEEI (references the ibek template)
- **template**: psEEI (references /ibek-templates/templates/ps/psEEI/)
- **devices**: List of power supply devices to control

## Device Configuration

Each device in the `devices` list should specify:

- **name**: Device name (used in PV naming)
- **ip**: IP address of the power supply
- **slave_id**: Modbus slave ID (default: 1)
- **max_curr**: Maximum current in mA (default: 330000)
- **timeout**: Communication timeout in ms (default: 1000)
- **rpoll**: Read polling time in ms (default: 1000)
- **wpoll**: Write polling time in ms (default: 0 = on demand)

## Example Configuration

```yaml
iocname: psmodbusEEI
iocprefix: EEI:PS
devtype: psEEI
template: psEEI
devices:
- ip: 192.168.190.153
  max_curr: 330000
  name: PS01
  slave_id: 1
  timeout: 1000
  rpoll: 1000
  wpoll: 0
```

## Building and Deploying

The IOC is built using the IBEK framework and deployed as a container through epik8s infrastructure.

## Database Records

The IOC provides extensive control and monitoring capabilities:

### Command Records
- `$(P):CMD_STANDBY` - Enter standby mode
- `$(P):CMD_POWER_ON` - Power on command
- `$(P):CMD_GLOBAL_OFF` - Global off command
- `$(P):CMD_RESET` - Reset command
- `$(P):CMD_START_RAMP` - Start ramping
- `$(P):CURR_SET` - Current setpoint
- `$(P):RAMP_RATE_SET` - Ramp rate setpoint

### Status Records
- `$(P):STAT_STANDBY` - Standby status
- `$(P):STAT_POWER_ON` - Power on status
- `$(P):STAT_FAULTY` - Fault status
- `$(P):STAT_REMOTE` - Remote/Local status
- `$(P):CURR_RB` - Current readback
- `$(P):VOLT_RB` - Voltage readback

### Fault Monitoring
- Multiple PLC, DC/DC, and AC/DC fault indicators
- Comprehensive temperature monitoring
- Contactor and interlock status

## Polarity Control

The IOC includes safety interlocks for polarity switching:
- Contactors must be opened before changing polarity
- Sequential records ensure safe operation
- Use `$(P):CMD_POLARITY_POS_REQ` or `$(P):CMD_POLARITY_NEG_REQ`

## Related Files

- **ibek-support**: `/ibek-support-infn/psEEI/`
- **template**: `/ibek-templates/templates/ps/psEEI/`
- **database**: In psmodbusEEI support module `/db/eei_ps.db`
