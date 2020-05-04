// I2C Power States
// Ensures that VoodooI2C can interface with the I2C controller
// Not needed on Acer E5-574G(-50TJ)

DefinitionBlock ("", "SSDT", 2, "hack", "I2C0", 0) {
    External(_SB.PCI0.I2C0, DeviceObj)
    External(_SB.PCI0.GETD, MethodObj)
    External(_SB.PCI0.LPD0, MethodObj)
    External(_SB.PCI0.LPD3, MethodObj)
    External(SB10, FieldUnitObj)

    Scope(_SB.PCI0.I2C0) {
        Method (_PSC, 0, NotSerialized)  // _PSC: Power State Current
        {
            Return (GETD (SB10))
        }

        Method (_PS0, 0, NotSerialized)  // _PS0: Power State 0
        {
            LPD0 (SB10)
        }

        Method (_PS3, 0, NotSerialized)  // _PS3: Power State 3
        {
            LPD3 (SB10)
        }
    }
}
