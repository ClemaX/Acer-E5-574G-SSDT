// Override OSYS to emulate Windows 2015 and disable dGPU
// Enabled if OSI reports Darwin

// OSYS value for Darwin
#define OSYS_DARWIN 3000
// Discrete GPU _OFF method ACPI path
#define DGPU_OFF \_SB_.PCI0.RP01.PXSX._OFF

DefinitionBlock ("", "SSDT", 2, "CLEMAX", "OSYS", 0) {
    External (OSYS, FieldUnitObj)
    External(DGPU_OFF, MethodObj)

    Scope (\_SB) {
        // Add a fake PCI Device
        Device (PCI1) {
            Name (_ADR, Zero)  // _ADR: Address

            Method (_INI, 0, Serialized) {  // _INI: Initialize
                // Set OSYS to OSYS_DARWIN
                If (CondRefOf (\OSYS))
                { \OSYS = OSYS_DARWIN }

                // Disable discrete graphics
                If (CondRefOf(DGPU_OFF))
                { DGPU_OFF() }
            }

            Method (_STA, 0, NotSerialized)  // _STA: Status
			{ Return (_OSI ("Darwin") & 0x0F) }
        }
    }
}
