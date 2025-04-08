/*
 * Bochs/QEMU ACPI DSDT ASL definition
 *
 * Copyright (c) 2006 Fabrice Bellard
 * Copyright (c) 2025 Benjamin David Lunt
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License version 2 as published by the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA
 *
 * This ASL code is based on Fabrice Bellard's original code, which
 *  was ASL 1.0 Syntax.
 * It is now ASL 2.0 Syntax and requires a v2.0 compatible compiler.
 * I use:
 *   Intel ACPI Component Architecture
 *   ASL+ Optimizing Compiler/Disassembler version 20241212 (32-bit version)
 *   Copyright (c) 2000 - 2023 Intel Corporation
 * with a command line of:
 *   iasl -ta -vr -p acpi-dsdt acpi-dsdt.dsl
 * which will produce:
 *   acpi_dsdt.hex
 *
 * Last Updated: 7 Apr 2025
 *
 */
DefinitionBlock ("", "DSDT", 1, "BXPC", "BXDSDT", 0x00000001)
{
    Scope (\)
    {
        OperationRegion (DBG, SystemIO, 0xB044, 0x04)
        Field (DBG, DWordAcc, NoLock, Preserve)
        {
            DBGL,   32
        }
    }

    Scope (_SB)
    {
        Device (PCI0)
        {
            Name (_HID, EisaId ("PNP0A03") /* PCI Bus */)  // _HID: Hardware ID
          //Name (_ADR, Zero)  // _ADR: Address
            Name (_UID, One)  // _UID: Unique ID
            Name (_PRT, Package (0x80)  // _PRT: PCI Routing Table
            {
                Package (0x04)
                {
                    0xFFFF, 
                    Zero, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    One, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    0x02, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0xFFFF, 
                    0x03, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0001FFFF, 
                    Zero, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0001FFFF, 
                    One, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0001FFFF, 
                    0x02, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0001FFFF, 
                    0x03, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0002FFFF, 
                    Zero, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0002FFFF, 
                    One, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0002FFFF, 
                    0x02, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0002FFFF, 
                    0x03, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0003FFFF, 
                    Zero, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0003FFFF, 
                    One, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0003FFFF, 
                    0x02, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0003FFFF, 
                    0x03, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0004FFFF, 
                    Zero, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0004FFFF, 
                    One, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0004FFFF, 
                    0x02, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0004FFFF, 
                    0x03, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0005FFFF, 
                    Zero, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0005FFFF, 
                    One, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0005FFFF, 
                    0x02, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0005FFFF, 
                    0x03, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0006FFFF, 
                    Zero, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0006FFFF, 
                    One, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0006FFFF, 
                    0x02, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0006FFFF, 
                    0x03, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0007FFFF, 
                    Zero, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0007FFFF, 
                    One, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0007FFFF, 
                    0x02, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0007FFFF, 
                    0x03, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0008FFFF, 
                    Zero, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0008FFFF, 
                    One, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0008FFFF, 
                    0x02, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0008FFFF, 
                    0x03, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0009FFFF, 
                    Zero, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0009FFFF, 
                    One, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0009FFFF, 
                    0x02, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0009FFFF, 
                    0x03, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000AFFFF, 
                    Zero, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000AFFFF, 
                    One, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000AFFFF, 
                    0x02, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000AFFFF, 
                    0x03, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000BFFFF, 
                    Zero, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000BFFFF, 
                    One, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000BFFFF, 
                    0x02, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000BFFFF, 
                    0x03, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000CFFFF, 
                    Zero, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000CFFFF, 
                    One, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000CFFFF, 
                    0x02, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000CFFFF, 
                    0x03, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000DFFFF, 
                    Zero, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000DFFFF, 
                    One, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000DFFFF, 
                    0x02, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000DFFFF, 
                    0x03, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000EFFFF, 
                    Zero, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000EFFFF, 
                    One, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000EFFFF, 
                    0x02, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000EFFFF, 
                    0x03, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000FFFFF, 
                    Zero, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000FFFFF, 
                    One, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000FFFFF, 
                    0x02, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x000FFFFF, 
                    0x03, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0010FFFF, 
                    Zero, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0010FFFF, 
                    One, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0010FFFF, 
                    0x02, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0010FFFF, 
                    0x03, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0011FFFF, 
                    Zero, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0011FFFF, 
                    One, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0011FFFF, 
                    0x02, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0011FFFF, 
                    0x03, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0012FFFF, 
                    Zero, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0012FFFF, 
                    One, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0012FFFF, 
                    0x02, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0012FFFF, 
                    0x03, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0013FFFF, 
                    Zero, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0013FFFF, 
                    One, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0013FFFF, 
                    0x02, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0013FFFF, 
                    0x03, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0014FFFF, 
                    Zero, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0014FFFF, 
                    One, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0014FFFF, 
                    0x02, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0014FFFF, 
                    0x03, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0015FFFF, 
                    Zero, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0015FFFF, 
                    One, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0015FFFF, 
                    0x02, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0015FFFF, 
                    0x03, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0016FFFF, 
                    Zero, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0016FFFF, 
                    One, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0016FFFF, 
                    0x02, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0016FFFF, 
                    0x03, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0017FFFF, 
                    Zero, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0017FFFF, 
                    One, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0017FFFF, 
                    0x02, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0017FFFF, 
                    0x03, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0018FFFF, 
                    Zero, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0018FFFF, 
                    One, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0018FFFF, 
                    0x02, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0018FFFF, 
                    0x03, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0019FFFF, 
                    Zero, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0019FFFF, 
                    One, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0019FFFF, 
                    0x02, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x0019FFFF, 
                    0x03, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001AFFFF, 
                    Zero, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001AFFFF, 
                    One, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001AFFFF, 
                    0x02, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001AFFFF, 
                    0x03, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001BFFFF, 
                    Zero, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001BFFFF, 
                    One, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001BFFFF, 
                    0x02, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001BFFFF, 
                    0x03, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001CFFFF, 
                    Zero, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001CFFFF, 
                    One, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001CFFFF, 
                    0x02, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001CFFFF, 
                    0x03, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001DFFFF, 
                    Zero, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001DFFFF, 
                    One, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001DFFFF, 
                    0x02, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001DFFFF, 
                    0x03, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001EFFFF, 
                    Zero, 
                    LNKB, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001EFFFF, 
                    One, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001EFFFF, 
                    0x02, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001EFFFF, 
                    0x03, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001FFFFF, 
                    Zero, 
                    LNKC, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001FFFFF, 
                    One, 
                    LNKD, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001FFFFF, 
                    0x02, 
                    LNKA, 
                    Zero
                }, 

                Package (0x04)
                {
                    0x001FFFFF, 
                    0x03, 
                    LNKB, 
                    Zero
                }
            })
            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                WordBusNumber (ResourceProducer, MinFixed, MaxFixed, PosDecode,
                    0x0000,             // Granularity
                    0x0000,             // Range Minimum
                    0x00FF,             // Range Maximum
                    0x0000,             // Translation Offset
                    0x0100,             // Length
                    ,, )
                IO (Decode16,
                    0x0CF8,             // Range Minimum
                    0x0CF8,             // Range Maximum
                    0x01,               // Alignment
                    0x08,               // Length
                    )
                WordIO (ResourceProducer, MinFixed, MaxFixed, PosDecode, EntireRange,
                    0x0000,             // Granularity
                    0x0000,             // Range Minimum
                    0x0CF7,             // Range Maximum
                    0x0000,             // Translation Offset
                    0x0CF8,             // Length
                    ,, , TypeStatic, DenseTranslation)
                WordIO (ResourceProducer, MinFixed, MaxFixed, PosDecode, EntireRange,
                    0x0000,             // Granularity
                    0x0D00,             // Range Minimum
                    0xFFFF,             // Range Maximum
                    0x0000,             // Translation Offset
                    0xF300,             // Length
                    ,, , TypeStatic, DenseTranslation)
                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x00000000,         // Granularity
                    0x000A0000,         // Range Minimum
                    0x000BFFFF,         // Range Maximum
                    0x00000000,         // Translation Offset
                    0x00020000,         // Length
                    ,, , AddressRangeMemory, TypeStatic)
                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, NonCacheable, ReadWrite,
                    0x00000000,         // Granularity
                    0xC0000000,         // Range Minimum
                    0xFEBFFFFF,         // Range Maximum
                    0x00000000,         // Translation Offset
                    0x3EC00000,         // Length
                    ,, , AddressRangeMemory, TypeStatic)
            })
        }

        Device (HPET)
        {
            Name (_HID, EisaId ("PNP0103") /* HPET System Timer */)  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (0x0F)
            }

            Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            {
                DWordMemory (ResourceConsumer, PosDecode, MinFixed, MaxFixed, NonCacheable, ReadWrite,
                    0x00000000,         // Granularity
                    0xFED00000,         // Range Minimum
                    0xFED003FF,         // Range Maximum
                    0x00000000,         // Translation Offset
                    0x00000400,         // Length
                    ,, , AddressRangeMemory, TypeStatic)
            })
        }
    }

    Scope (_SB.PCI0)
    {
        Device (VGA)
        {
            Name (_ADR, 0x00020000)  // _ADR: Address
            Method (_S1D, 0, NotSerialized)  // _S1D: S1 Device State
            {
                Return (Zero)
            }

            Method (_S2D, 0, NotSerialized)  // _S2D: S2 Device State
            {
                Return (Zero)
            }

            Method (_S3D, 0, NotSerialized)  // _S3D: S3 Device State
            {
                Return (Zero)
            }
        }

        Device (ISA)
        {
            Name (_ADR, 0x00010000)  // _ADR: Address
            OperationRegion (P40C, PCI_Config, 0x60, 0x04)
            Device (RTC)
            {
                Name (_HID, EisaId ("PNP0B00") /* AT Real-Time Clock */)  // _HID: Hardware ID
                Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
                {
                    IO (Decode16,
                        0x0070,             // Range Minimum
                        0x0070,             // Range Maximum
                        0x10,               // Alignment
                        0x02,               // Length
                        )
                    IRQNoFlags ()
                        {8}
                    IO (Decode16,
                        0x0072,             // Range Minimum
                        0x0072,             // Range Maximum
                        0x02,               // Alignment
                        0x06,               // Length
                        )
                })
            }

            Device (KBD)
            {
                Name (_HID, EisaId ("PNP0303") /* IBM Enhanced Keyboard (101/102-key, PS/2 Mouse) */)  // _HID: Hardware ID
                Method (_STA, 0, NotSerialized)  // _STA: Status
                {
                    Return (0x0F)
                }

                Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
                {
                    Name (TMP, ResourceTemplate ()
                    {
                        IO (Decode16,
                            0x0060,             // Range Minimum
                            0x0060,             // Range Maximum
                            0x01,               // Alignment
                            0x01,               // Length
                            )
                        IO (Decode16,
                            0x0064,             // Range Minimum
                            0x0064,             // Range Maximum
                            0x01,               // Alignment
                            0x01,               // Length
                            )
                        IRQNoFlags ()
                            {1}
                    })
                    Return (TMP) /* \_SB_.PCI0.ISA_.KBD_._CRS.TMP_ */
                }
            }

            Device (MOU)
            {
                Name (_HID, EisaId ("PNP0F13") /* PS/2 Mouse */)  // _HID: Hardware ID
                Method (_STA, 0, NotSerialized)  // _STA: Status
                {
                    Return (0x0F)
                }

                Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
                {
                    Name (TMP, ResourceTemplate ()
                    {
                        IRQNoFlags ()
                            {12}
                    })
                    Return (TMP) /* \_SB_.PCI0.ISA_.MOU_._CRS.TMP_ */
                }
            }

            Device (FDC0)
            {
                Name (_HID, EisaId ("PNP0700"))  // _HID: Hardware ID
                Method (_STA, 0, NotSerialized)  // _STA: Status
                {
                    Return (0x0F)
                }

                Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
                {
                    Name (BUF0, ResourceTemplate ()
                    {
                        IO (Decode16,
                            0x03F2,             // Range Minimum
                            0x03F2,             // Range Maximum
                            0x00,               // Alignment
                            0x04,               // Length
                            )
                        IO (Decode16,
                            0x03F7,             // Range Minimum
                            0x03F7,             // Range Maximum
                            0x00,               // Alignment
                            0x01,               // Length
                            )
                        IRQNoFlags ()
                            {6}
                        DMA (Compatibility, NotBusMaster, Transfer8, )
                            {2}
                    })
                    Return (BUF0) /* \_SB_.PCI0.ISA_.FDC0._CRS.BUF0 */
                }
            }

            Device (LPT)
            {
                Name (_HID, EisaId ("PNP0400") /* Standard LPT Parallel Port */)  // _HID: Hardware ID
                Method (_STA, 0, NotSerialized)  // _STA: Status
                {
                    Local0 = ^^^PX13.DRSA /* \_SB_.PCI0.PX13.DRSA */
                    Local0 &= 0x80000000
                    If ((Local0 == Zero))
                    {
                        Return (Zero)
                    }
                    Else
                    {
                        Return (0x0F)
                    }
                }

                Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
                {
                    Name (BUF0, ResourceTemplate ()
                    {
                        IO (Decode16,
                            0x0378,             // Range Minimum
                            0x0378,             // Range Maximum
                            0x08,               // Alignment
                            0x08,               // Length
                            )
                        IRQNoFlags ()
                            {7}
                    })
                    Return (BUF0) /* \_SB_.PCI0.ISA_.LPT_._CRS.BUF0 */
                }
            }

            Device (COM1)
            {
                Name (_HID, EisaId ("PNP0501") /* 16550A-compatible COM Serial Port */)  // _HID: Hardware ID
                Name (_UID, One)  // _UID: Unique ID
                Method (_STA, 0, NotSerialized)  // _STA: Status
                {
                    Local0 = ^^^PX13.DRSC /* \_SB_.PCI0.PX13.DRSC */
                    Local0 &= 0x08000000
                    If ((Local0 == Zero))
                    {
                        Return (Zero)
                    }
                    Else
                    {
                        Return (0x0F)
                    }
                }

                Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
                {
                    Name (BUF0, ResourceTemplate ()
                    {
                        IO (Decode16,
                            0x03F8,             // Range Minimum
                            0x03F8,             // Range Maximum
                            0x00,               // Alignment
                            0x08,               // Length
                            )
                        IRQNoFlags ()
                            {4}
                    })
                    Return (BUF0) /* \_SB_.PCI0.ISA_.COM1._CRS.BUF0 */
                }
            }

            Device (COM2)
            {
                Name (_HID, EisaId ("PNP0501") /* 16550A-compatible COM Serial Port */)  // _HID: Hardware ID
                Name (_UID, 0x02)  // _UID: Unique ID
                Method (_STA, 0, NotSerialized)  // _STA: Status
                {
                    Local0 = ^^^PX13.DRSC /* \_SB_.PCI0.PX13.DRSC */
                    Local0 &= 0x80000000
                    If ((Local0 == Zero))
                    {
                        Return (Zero)
                    }
                    Else
                    {
                        Return (0x0F)
                    }
                }

                Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
                {
                    Name (BUF0, ResourceTemplate ()
                    {
                        IO (Decode16,
                            0x02F8,             // Range Minimum
                            0x02F8,             // Range Maximum
                            0x00,               // Alignment
                            0x08,               // Length
                            )
                        IRQNoFlags ()
                            {3}
                    })
                    Return (BUF0) /* \_SB_.PCI0.ISA_.COM2._CRS.BUF0 */
                }
            }
        }

        Device (PX13)
        {
            Name (_ADR, 0x00010003)  // _ADR: Address
            OperationRegion (P13C, PCI_Config, 0x5C, 0x24)
            Field (P13C, DWordAcc, NoLock, Preserve)
            {
                DRSA,   32, 
                DRSB,   32, 
                DRSC,   32, 
                DRSE,   32, 
                DRSF,   32, 
                DRSG,   32, 
                DRSH,   32, 
                DRSI,   32, 
                DRSJ,   32
            }
        }
    }

    Scope (_SB)
    {
        Field (PCI0.ISA.P40C, ByteAcc, NoLock, Preserve)
        {
            PRQ0,   8, 
            PRQ1,   8, 
            PRQ2,   8, 
            PRQ3,   8
        }

        Device (LNKA)
        {
            Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
            Name (_UID, One)  // _UID: Unique ID
            Name (_PRS, ResourceTemplate ()  // _PRS: Possible Resource Settings
            {
                IRQ (Level, ActiveLow, Shared, )
                    {3,4,5,6,7,9,10,11,12}
            })
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Local0 = 0x0B
                If (0x80 & PRQ0 /* \_SB_.PRQ0 */)
                {
                    Local0 = 0x09
                }

                Return (Local0)
            }

            Method (_DIS, 0, NotSerialized)  // _DIS: Disable Device
            {
                PRQ0 |= 0x80
            }

            Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
            {
                Name (PRR0, ResourceTemplate ()
                {
                    IRQ (Level, ActiveLow, Shared, )
                        {1}
                })
                CreateWordField (PRR0, One, TMP)
                Local0 = PRQ0 /* \_SB_.PRQ0 */
                If ((Local0 < 0x80))
                {
                    TMP = (One << Local0)
                }
                Else
                {
                    TMP = Zero
                }

                Return (PRR0) /* \_SB_.LNKA._CRS.PRR0 */
            }

            Method (_SRS, 1, NotSerialized)  // _SRS: Set Resource Settings
            {
                CreateWordField (Arg0, One, TMP)
                FindSetRightBit (TMP, Local0)
                Local0--
                PRQ0 = Local0
            }
        }

        Device (LNKB)
        {
            Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
            Name (_UID, 0x02)  // _UID: Unique ID
            Name (_PRS, ResourceTemplate ()  // _PRS: Possible Resource Settings
            {
                IRQ (Level, ActiveLow, Shared, )
                    {3,4,5,6,7,9,10,11,12}
            })
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Local0 = 0x0B
                If (0x80 & PRQ1 /* \_SB_.PRQ1 */)
                {
                    Local0 = 0x09
                }

                Return (Local0)
            }

            Method (_DIS, 0, NotSerialized)  // _DIS: Disable Device
            {
                PRQ1 |= 0x80
            }

            Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
            {
                Name (PRR0, ResourceTemplate ()
                {
                    IRQ (Level, ActiveLow, Shared, )
                        {1}
                })
                CreateWordField (PRR0, One, TMP)
                Local0 = PRQ1 /* \_SB_.PRQ1 */
                If ((Local0 < 0x80))
                {
                    TMP = (One << Local0)
                }
                Else
                {
                    TMP = Zero
                }

                Return (PRR0) /* \_SB_.LNKB._CRS.PRR0 */
            }

            Method (_SRS, 1, NotSerialized)  // _SRS: Set Resource Settings
            {
                CreateWordField (Arg0, One, TMP)
                FindSetRightBit (TMP, Local0)
                Local0--
                PRQ1 = Local0
            }
        }

        Device (LNKC)
        {
            Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
            Name (_UID, 0x03)  // _UID: Unique ID
            Name (_PRS, ResourceTemplate ()  // _PRS: Possible Resource Settings
            {
                IRQ (Level, ActiveLow, Shared, )
                    {3,4,5,6,7,9,10,11,12}
            })
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Local0 = 0x0B
                If (0x80 & PRQ2 /* \_SB_.PRQ2 */)
                {
                    Local0 = 0x09
                }

                Return (Local0)
            }

            Method (_DIS, 0, NotSerialized)  // _DIS: Disable Device
            {
                PRQ2 |= 0x80
            }

            Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
            {
                Name (PRR0, ResourceTemplate ()
                {
                    IRQ (Level, ActiveLow, Shared, )
                        {1}
                })
                CreateWordField (PRR0, One, TMP)
                Local0 = PRQ2 /* \_SB_.PRQ2 */
                If ((Local0 < 0x80))
                {
                    TMP = (One << Local0)
                }
                Else
                {
                    TMP = Zero
                }

                Return (PRR0) /* \_SB_.LNKC._CRS.PRR0 */
            }

            Method (_SRS, 1, NotSerialized)  // _SRS: Set Resource Settings
            {
                CreateWordField (Arg0, One, TMP)
                FindSetRightBit (TMP, Local0)
                Local0--
                PRQ2 = Local0
            }
        }

        Device (LNKD)
        {
            Name (_HID, EisaId ("PNP0C0F") /* PCI Interrupt Link Device */)  // _HID: Hardware ID
            Name (_UID, 0x04)  // _UID: Unique ID
            Name (_PRS, ResourceTemplate ()  // _PRS: Possible Resource Settings
            {
                IRQ (Level, ActiveLow, Shared, )
                    {3,4,5,6,7,9,10,11,12}
            })
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Local0 = 0x0B
                If (0x80 & PRQ3 /* \_SB_.PRQ3 */)
                {
                    Local0 = 0x09
                }

                Return (Local0)
            }

            Method (_DIS, 0, NotSerialized)  // _DIS: Disable Device
            {
                PRQ3 |= 0x80
            }

            Method (_CRS, 0, NotSerialized)  // _CRS: Current Resource Settings
            {
                Name (PRR0, ResourceTemplate ()
                {
                    IRQ (Level, ActiveLow, Shared, )
                        {1}
                })
                CreateWordField (PRR0, One, TMP)
                Local0 = PRQ3 /* \_SB_.PRQ3 */
                If ((Local0 < 0x80))
                {
                    TMP = (One << Local0)
                }
                Else
                {
                    TMP = Zero
                }

                Return (PRR0) /* \_SB_.LNKD._CRS.PRR0 */
            }

            Method (_SRS, 1, NotSerialized)  // _SRS: Set Resource Settings
            {
                CreateWordField (Arg0, One, TMP)
                FindSetRightBit (TMP, Local0)
                Local0--
                PRQ3 = Local0
            }
        }
    }

    Name (_S3, Package (0x04)  // _S3_: S3 System State
    {
        One, 
        One, 
        Zero, 
        Zero
    })
    Name (_S4, Package (0x04)  // _S4_: S4 System State
    {
        Zero, 
        Zero, 
        Zero, 
        Zero
    })
    Name (_S5, Package (0x04)  // _S5_: S5 System State
    {
        Zero, 
        Zero, 
        Zero, 
        Zero
    })
}
