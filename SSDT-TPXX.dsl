// Enables GPI0 interrupts for ELAN0501 on Acer E5-574G(-50TJ)

// Using pin 0x3A
#define GPIO_PIN 0x003A

DefinitionBlock ("", "SSDT", 2, "CLEMAX", "I2C-TPXX", 0) {
    External(_SB.PCI0.I2C0, DeviceObj)
    External(OSYS, FieldUnitObj)  // OSYS: OS Version Identifier
    External(TPVD, FieldUnitObj)  // TPVD: Trackpad Vendor
    External(_SB.PTPS, FieldUnitObj)  // PTPS: Pointer Setting

    Scope(\)
    {
        If (_OSI ("Darwin"))
        {
            // Disable other pointing devices on macOS
            \_SB.PTPS = 0
        }
    }

    // path: _SB.PCI0.I2C0.TPDE
    Scope(_SB.PCI0.I2C0)
	{
        Device (TPXX)
        {
            Name (_ADR, Zero)  // _ADR: Address
            Name (_HID, "ELAN0501")  // _HID: Hardware ID
            Name (_CID, "PNP0C50" /* HID Protocol Device (I2C bus) */)  // _CID: Compatible ID
            Name (_UID, One)  // _UID: Unique ID
            Method (_DSM, 4, NotSerialized)  // _DSM: Device-Specific Method
            {
                If ((Arg0 == ToUUID ("3cdff6f7-4267-4555-ad05-b30a3d8938de") /* HID I2C Device */))
                {
                    If ((Arg2 == Zero))
                    {
                        If ((Arg1 == One))
                        {
                            Return (Buffer (One)
                            {
                                 0x03                                             // .
                            })
                        }
                        Else
                        {
                            Return (Buffer (One)
                            {
                                 0x00                                             // .
                            })
                        }
                    }

                    If ((Arg2 == One))
                    {
                        Return (One)
                    }
                }
                Else
                {
                    Return (Buffer (One)
                    {
                         0x00                                             // .
                    })
                }
            }

            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                // Enable TPXX on macOS
                If (_OSI ("Darwin"))
                {
                    Return (0x0F)
                }

                If ((PTPS == Zero))
                {
                    Return (Zero)
                }

                If ((TPVD == 0x45))
                {
                    If ((OSYS >= 0x07DD))
                    {
                        Return (0x0F)
                    }
                    Else
                    {
                        Return (Zero)
                    }
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
            {
                // Declare GPIO Interrupt instead of APIC Interrupt
                Name (SBFG, ResourceTemplate ()
                {
                    GpioInt (Level, ActiveLow, ExclusiveAndWake, PullDefault, 0x0000,
                        "\\_SB.PCI0.GPI0", 0x00, ResourceConsumer, ,
                        )
                        {   // Pin list
                            GPIO_PIN
                        }
                })

                Name (SBFB, ResourceTemplate ()
                {
                    I2cSerialBusV2 (0x0015, ControllerInitiated, 0x00061A80,
                        AddressingMode7Bit, "\\_SB.PCI0.I2C0",
                        0x00, ResourceConsumer, , Exclusive,
                        )
                })

                Return (ConcatenateResTemplate (SBFB, SBFG))
            }
        }
    }
}
