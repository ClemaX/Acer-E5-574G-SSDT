// Enables GPI0 interrupts for ELAN0501 on Acer E5-574G(-50TJ)

// Using pin 0x3A
#define GPIO_PIN 0x3A

// Enabled when OSYS is Darwin or superior
#define OSYS_DARWIN 3000

// Synaptics Trackpad Configuration
#define SYNAPTICS_HID "SYN1B81"
#define SYNAPTICS_TPVD 0x01
#define SYNAPTICS_I2C 0x2C

// Elan Trackpad Configuration
#define ELAN_HID "ELAN0501"
#define ELAN_TPVD 0x45
#define ELAN_I2C 0x15

DefinitionBlock ("", "SSDT", 2, "CLEMAX", "I2C-TPXX", 0)
{
    External(_SB_.PCI0.I2C0, DeviceObj) // I2C0: I2C Controller

    If (_OSI("Darwin")) { 
        Scope (\_SB.PCI0.I2C0) {
            // Disable other precision trackpad devices
            Name (PTPS, Zero)

            Device (TPXX) {
                //Name (_ADR, Zero)  // _ADR: Address
                Name (_HID, ELAN_HID)  // _HID: Hardware ID
                Name (_CID, "PNP0C50" /* HID Protocol Device (I2C bus) */)  // _CID: Compatible ID
                Name (_UID, One)  // _UID: Unique ID

                Method (_DSM, 4, NotSerialized) {  // _DSM: Device-Specific Method
                    If ((Arg0 == ToUUID ("3cdff6f7-4267-4555-ad05-b30a3d8938de") /* HID I2C Device */)) {
                        If ((Arg2 == Zero)) {
                            If ((Arg1 == One))
                            { Return (Buffer (One) { 0x03 }) }
                        }
                        ElseIf ((Arg2 == One))
                        { Return (One) }
                    }
                    
                    Return (Buffer (One) { 0x00 })
                }

                Method (_STA, 0, NotSerialized)  // _STA: Status
				{ Return (0x0F) }

                // Remove ACPI Interrupt
                Name (SBFB, ResourceTemplate () {
                    I2cSerialBusV2 (ELAN_I2C, ControllerInitiated, 0x00061A80,
                        AddressingMode7Bit, "\\_SB.PCI0.I2C0",
                        0x00, ResourceConsumer, , Exclusive,
                        )
                        /*
                        Interrupt (ResourceConsumer, Edge, ActiveLow, Exclusive, ,, )
                        { 0x00000052, }
                        */
                })

                // Define GPIO Interrupt
                Name (SBFG, ResourceTemplate () {
                    GpioInt (Level, ActiveLow, ExclusiveAndWake, PullDefault, 0x0000,
                        "\\_SB.PCI0.GPI0", 0x00, ResourceConsumer, ,
                        ) { GPIO_PIN }
                })

                Method (_CRS, 0, Serialized)  // _CRS: Current Resource Settings
                { Return (ConcatenateResTemplate (SBFB, SBFG)) }
            }
        }
    }
}
