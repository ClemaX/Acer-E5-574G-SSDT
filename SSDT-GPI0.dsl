// Enable GPIO on macOS

DefinitionBlock("", "SSDT", 2, "ACDT", "GPI0", 0)
{
    External(GPEN, FieldUnitObj)
    External(SBRG, FieldUnitObj)

    Scope (\)
    {
        If (_OSI ("Darwin"))
        {
            GPEN = One
            SBRG = One
        }
    }
}

