// Override OSYS to emulate Windows 2015
// Enabled if the OSI reports Darwin

#define OSYS_DARWIN 3000

DefinitionBlock ("", "SSDT", 2, "CLEMAX", "OSYS", 0) {
    External (OSYS, FieldUnitObj)

    Scope (\_SB) {
        // Add a fake PCI Device
        Device (PCI1) {
            Name (_ADR, Zero)  // _ADR: Address

            Method (_INI, 0, Serialized) {  // _INI: Initialize
                // Set OSYS to 
                If (CondRefOf (\OSYS))
                { \OSYS = OSYS_DARWIN }
            }

            Method (_STA, 0, NotSerialized) {  // _STA: Status
                Return (_OSI ("Darwin") & 0x0F)
            }
        }
    }
}
