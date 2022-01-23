// Adding PNLF device for WhateverGreen.kext and others.
// This is a modified PNLF version originally taken from RehabMan/OS-X-Clover-Laptop-Config repository:
// https://raw.githubusercontent.com/RehabMan/OS-X-Clover-Laptop-Config/master/hotpatch/SSDT-PNLF.dsl
// Rename GFX0 to anything else if your IGPU name is different.
//
// Licensed under GNU General Public License v2.0
// https://github.com/RehabMan/OS-X-Clover-Laptop-Config/blob/master/License.md

#define FBTYPE_SANDYIVY 1
#define FBTYPE_HSWPLUS 2
#define FBTYPE_CFL 3

#define SANDYIVY_PWMMAX 0x710
#define HASWELL_PWMMAX 0xad9
#define SKYLAKE_PWMMAX 0x56c
#define CUSTOM_PWMMAX_07a1 0x07a1
#define CUSTOM_PWMMAX_1499 0x1499
#define COFFEELAKE_PWMMAX 0xffff

DefinitionBlock("", "SSDT", 2, "ACDT", "PNLF", 0)
{
    External(RMCF.BKLT, IntObj)
    External(RMCF.LMAX, IntObj)
    External(RMCF.LEVW, IntObj)
    External(RMCF.GRAN, IntObj)
    External(RMCF.FBTP, IntObj)

    External(_SB.PCI0.GFX0, DeviceObj)
    Scope(_SB.PCI0.GFX0)
    {
        OperationRegion(RMP3, PCI_Config, 0, 0x14)
    }

    // For backlight control
    Device(_SB.PCI0.GFX0.PNLF)
    {
        Name(_HID, EisaId("APP0002"))
        Name(_CID, "backlight")
        // _UID is set depending on PWMMax to match profiles in WhateverGreen.kext Info.plist
        // 14: Sandy/Ivy 0x710
        // 15: Haswell/Broadwell 0xad9
        // 16: Skylake/KabyLake 0x56c (and some Haswell, example 0xa2e0008)
        // 17: custom LMAX=0x7a1
        // 18: custom LMAX=0x1499
        // 19: CoffeeLake 0xffff
        // 99: Other (requires custom AppleBacklightInjector.kext/WhateverGreen.kext)
        Name(_UID, 0)
        Name(_STA, 0x0B)

        Field(^RMP3, AnyAcc, NoLock, Preserve)
        {
            Offset(0x02), GDID,16,
            Offset(0x10), BAR1,32,
        }

        // IGPU PWM backlight register descriptions:
        //   LEV2 not currently used
        //   LEVL level of backlight in Sandy/Ivy
        //   P0BL counter, when zero is vertical blank
        //   GRAN see description below in INI1 method
        //   LEVW should be initialized to 0xC0000000
        //   LEVX PWMMax except FBTYPE_HSWPLUS combo of max/level (Sandy/Ivy stored in MSW)
        //   LEVD level of backlight for Coffeelake
        //   PCHL not currently used
        OperationRegion(RMB1, SystemMemory, BAR1 & ~0xF, 0xe1184)
        Field(RMB1, AnyAcc, Lock, Preserve)
        {
            Offset(0x48250),
            LEV2, 32,
            LEVL, 32,
            Offset(0x70040),
            P0BL, 32,
            Offset(0xc2000),
            GRAN, 32,
            Offset(0xc8250),
            LEVW, 32,
            LEVX, 32,
            LEVD, 32,
            Offset(0xe1180),
            PCHL, 32,
        }

        Method(_INI)
        {
            // IntelBacklight.kext takes care of this at load time...
            // If RMCF.BKLT does not exist, it is assumed you want to use AppleBacklight.kext...
            Local4 = 1
            If (CondRefOf(\RMCF.BKLT)) { Local4 = \RMCF.BKLT }
            If (!(1 & Local4)) { Return }

            // Adjustment required when using AppleBacklight.kext
            Local0 = ^GDID
            Local2 = Ones
            If (CondRefOf(\RMCF.LMAX)) { Local2 = \RMCF.LMAX }

            // Now fixup the backlight PWM depending on the framebuffer type
            // At this point:
            //   Local4 is RMCF.BLKT value, if specified (default is 1)
            //   Local0 is device-id for IGPU
            //   Local2 is LMAX, if specified (Ones means based on device-id)

            // must be Haswell/Broadwell/Skylake/KabyLake/KabyLake-R (FBTYPE_HSWPLUS)
			if (Ones == Local2)
			{
				// assume Skylake/KabyLake/KabyLake-R, both 0x56c
				// 0x1916, 0x191E, 0x1926, 0x1927, 0x1912, 0x1932, 0x1902, 0x1917, 0x191b,
				// 0x5916, 0x5912, 0x591b, others...
				Local2 = SKYLAKE_PWMMAX
			}

			// INTEL OPEN SOURCE HD GRAPHICS, INTEL IRIS GRAPHICS, AND INTEL IRIS PRO GRAPHICS PROGRAMMER'S REFERENCE MANUAL (PRM)
            // FOR THE 2015-2016 INTEL CORE PROCESSORS, CELERON PROCESSORS AND PENTIUM PROCESSORS BASED ON THE "SKYLAKE" PLATFORM
            // Volume 12: Display (https://01.org/sites/default/files/documentation/intel-gfx-prm-osrc-skl-vol12-display.pdf)
            //   page 189
            //   Backlight Enabling Sequence
            //   Description
            //   1. Set frequency and duty cycle in SBLC_PWM_CTL2 Backlight Modulation Frequency and Backlight Duty Cycle.
            //   2. Set granularity in 0xC2000 bit 0 (0 = 16, 1 = 128).
            //   3. Enable PWM output and set polarity in SBLC_PWM_CTL1 PWM PCH Enable and Backlight Polarity.
            //   4. Change duty cycle as needed in SBLC_PWM_CTL2 Backlight Duty Cycle.
            // This 0xC value comes from looking what OS X initializes this
            // register to after display sleep (using ACPIDebug/ACPIPoller)
            If (0 == (2 & Local4))
            {
                Local5 = 0xC0000000
                If (CondRefOf(\RMCF.LEVW)) { If (Ones != \RMCF.LEVW) { Local5 = \RMCF.LEVW } }
                ^LEVW = Local5
            }

            // from step 2 above (you may need 1 instead)
            If (4 & Local4)
            {
                If (CondRefOf(\RMCF.GRAN)) { ^GRAN = \RMCF.GRAN }
                Else { ^GRAN = 0 }
            }

			// change/scale only if different than current...
			Local1 = ^LEVX >> 16
			If (!Local1) { Local1 = Local2 }
			If (!(8 & Local4) && Local2 != Local1)
			{
				// set new backlight PWMAX but retain current backlight level by scaling
				Local0 = (((^LEVX & 0xFFFF) * Local2) / Local1) | (Local2 << 16)
				//REVIEW: wait for vblank before setting new PWM config
				//For (Local7 = ^P0BL, ^P0BL == Local7, ) { }
				^LEVX = Local0
			}

            // Now Local2 is the new PWMMax, set _UID accordingly
            // The _UID selects the correct entry in AppleBacklightFixup.kext
            If(Local2 == SKYLAKE_PWMMAX) { _UID = 16 }
            ElseIf (Local2 == CUSTOM_PWMMAX_07a1) { _UID = 17 }
            ElseIf (Local2 == CUSTOM_PWMMAX_1499) { _UID = 18 }
            Else { _UID = 99 }
        }
    }
}
