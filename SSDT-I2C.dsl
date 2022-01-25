// I2C Power States
// Ensures that VoodooI2C can interface with the I2C controller

DefinitionBlock ("", "SSDT", 2, "CLEMAX", "I2C0", 0) {
    External(_SB.PCI0.I2C0, DeviceObj)
    External(_SB.PCI0.GETD, MethodObj)
    External(_SB.PCI0.LPD0, MethodObj)
    External(_SB.PCI0.LPD3, MethodObj)
    External(PKG3, MethodObj)
    External(SB10, FieldUnitObj)
    External(SSHI, FieldUnitObj)
    External(SSLI, FieldUnitObj)
    External(SSDI, FieldUnitObj)
    External(FMHI, FieldUnitObj)
    External(FMLI, FieldUnitObj)
    External(FMDI, FieldUnitObj)

    If (_OSI ("Darwin")) {
        Scope(_SB.PCI0.I2C0) {
            Method (_PSC, 0, NotSerialized)  // _PSC: Power State Current
            { Return (GETD (SB10)) }

            Method (_PS0, 0, NotSerialized)  // _PS0: Power State 0
            { LPD0 (SB10) }

            Method (_PS3, 0, NotSerialized)  // _PS3: Power State 3
            { LPD3 (SB10) }

            Method (SSCN, 0, NotSerialized)  // SSCN: Standard mode Clock Speed
            { Return (PKG3 (SSHI, SSLI, SSDI)) }

            Method (FMCN, 0, NotSerialized)  // FMCN: Fast mode Clock Speed
            { Return (PKG3 (FMHI, FMLI, FMDI)) }
        }
    }
}
