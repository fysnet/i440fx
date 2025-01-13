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
 * Last Updated: 12 Jan 2025
 *
 */

DefinitionBlock (
  "acpi-dsdt.aml", // Output Filename
  "DSDT",          // Signature
  0x01,            // DSDT Compliance Revision
  "BXPC",          // OEMID
  "BXDSDT",        // TABLE ID
  0x1              // OEM Revision
  ) {
    Scope (\) {
      /* Debug Output */
      OperationRegion (DBG, SystemIO, 0xb044, 0x04)
      Field (DBG, DWordAcc, NoLock, Preserve) {
        DBGL, 32,
      }
    }
    
    /* PCI Bus definition */
    Scope(\_SB) {
      Device(PCI0) {
        Name (_HID, EisaId ("PNP0A03"))
        Name (_UID, 1)
        Name(_PRT, Package() {
          /* PCI IRQ routing table, example from ACPI 2.0a specification, section 6.2.8.1 */
          /* Note: we provide the same info as the PCI routing table of the Bochs BIOS */
          Package(4) { 0x0000FFFF, 0, LNKD, 0 }, Package(4) { 0x0000FFFF, 1, LNKA, 0 }, Package(4) { 0x0000FFFF, 2, LNKB, 0 }, Package(4) { 0x0000FFFF, 3, LNKC, 0 },
          Package(4) { 0x0001FFFF, 0, LNKA, 0 }, Package(4) { 0x0001FFFF, 1, LNKB, 0 }, Package(4) { 0x0001FFFF, 2, LNKC, 0 }, Package(4) { 0x0001FFFF, 3, LNKD, 0 },
          Package(4) { 0x0002FFFF, 0, LNKB, 0 }, Package(4) { 0x0002FFFF, 1, LNKC, 0 }, Package(4) { 0x0002FFFF, 2, LNKD, 0 }, Package(4) { 0x0002FFFF, 3, LNKA, 0 },
          Package(4) { 0x0003FFFF, 0, LNKC, 0 }, Package(4) { 0x0003FFFF, 1, LNKD, 0 }, Package(4) { 0x0003FFFF, 2, LNKA, 0 }, Package(4) { 0x0003FFFF, 3, LNKB, 0 },
          Package(4) { 0x0004FFFF, 0, LNKD, 0 }, Package(4) { 0x0004FFFF, 1, LNKA, 0 }, Package(4) { 0x0004FFFF, 2, LNKB, 0 }, Package(4) { 0x0004FFFF, 3, LNKC, 0 },
          Package(4) { 0x0005FFFF, 0, LNKA, 0 }, Package(4) { 0x0005FFFF, 1, LNKB, 0 }, Package(4) { 0x0005FFFF, 2, LNKC, 0 }, Package(4) { 0x0005FFFF, 3, LNKD, 0 },
          Package(4) { 0x0006FFFF, 0, LNKB, 0 }, Package(4) { 0x0006FFFF, 1, LNKC, 0 }, Package(4) { 0x0006FFFF, 2, LNKD, 0 }, Package(4) { 0x0006FFFF, 3, LNKA, 0 },
          Package(4) { 0x0007FFFF, 0, LNKC, 0 }, Package(4) { 0x0007FFFF, 1, LNKD, 0 }, Package(4) { 0x0007FFFF, 2, LNKA, 0 }, Package(4) { 0x0007FFFF, 3, LNKB, 0 },
          Package(4) { 0x0008FFFF, 0, LNKD, 0 }, Package(4) { 0x0008FFFF, 1, LNKA, 0 }, Package(4) { 0x0008FFFF, 2, LNKB, 0 }, Package(4) { 0x0008FFFF, 3, LNKC, 0 },
          Package(4) { 0x0009FFFF, 0, LNKA, 0 }, Package(4) { 0x0009FFFF, 1, LNKB, 0 }, Package(4) { 0x0009FFFF, 2, LNKC, 0 }, Package(4) { 0x0009FFFF, 3, LNKD, 0 },
          Package(4) { 0x000AFFFF, 0, LNKB, 0 }, Package(4) { 0x000AFFFF, 1, LNKC, 0 }, Package(4) { 0x000AFFFF, 2, LNKD, 0 }, Package(4) { 0x000AFFFF, 3, LNKA, 0 },
          Package(4) { 0x000BFFFF, 0, LNKC, 0 }, Package(4) { 0x000BFFFF, 1, LNKD, 0 }, Package(4) { 0x000BFFFF, 2, LNKA, 0 }, Package(4) { 0x000BFFFF, 3, LNKB, 0 },
          Package(4) { 0x000CFFFF, 0, LNKD, 0 }, Package(4) { 0x000CFFFF, 1, LNKA, 0 }, Package(4) { 0x000CFFFF, 2, LNKB, 0 }, Package(4) { 0x000CFFFF, 3, LNKC, 0 },
          Package(4) { 0x000DFFFF, 0, LNKA, 0 }, Package(4) { 0x000DFFFF, 1, LNKB, 0 }, Package(4) { 0x000DFFFF, 2, LNKC, 0 }, Package(4) { 0x000DFFFF, 3, LNKD, 0 },
          Package(4) { 0x000EFFFF, 0, LNKB, 0 }, Package(4) { 0x000EFFFF, 1, LNKC, 0 }, Package(4) { 0x000EFFFF, 2, LNKD, 0 }, Package(4) { 0x000EFFFF, 3, LNKA, 0 },
          Package(4) { 0x000FFFFF, 0, LNKC, 0 }, Package(4) { 0x000FFFFF, 1, LNKD, 0 }, Package(4) { 0x000FFFFF, 2, LNKA, 0 }, Package(4) { 0x000FFFFF, 3, LNKB, 0 },
          Package(4) { 0x0010FFFF, 0, LNKD, 0 }, Package(4) { 0x0010FFFF, 1, LNKA, 0 }, Package(4) { 0x0010FFFF, 2, LNKB, 0 }, Package(4) { 0x0010FFFF, 3, LNKC, 0 },
          Package(4) { 0x0011FFFF, 0, LNKA, 0 }, Package(4) { 0x0011FFFF, 1, LNKB, 0 }, Package(4) { 0x0011FFFF, 2, LNKC, 0 }, Package(4) { 0x0011FFFF, 3, LNKD, 0 },
          Package(4) { 0x0012FFFF, 0, LNKB, 0 }, Package(4) { 0x0012FFFF, 1, LNKC, 0 }, Package(4) { 0x0012FFFF, 2, LNKD, 0 }, Package(4) { 0x0012FFFF, 3, LNKA, 0 },
          Package(4) { 0x0013FFFF, 0, LNKC, 0 }, Package(4) { 0x0013FFFF, 1, LNKD, 0 }, Package(4) { 0x0013FFFF, 2, LNKA, 0 }, Package(4) { 0x0013FFFF, 3, LNKB, 0 },
          Package(4) { 0x0014FFFF, 0, LNKD, 0 }, Package(4) { 0x0014FFFF, 1, LNKA, 0 }, Package(4) { 0x0014FFFF, 2, LNKB, 0 }, Package(4) { 0x0014FFFF, 3, LNKC, 0 },
          Package(4) { 0x0015FFFF, 0, LNKA, 0 }, Package(4) { 0x0015FFFF, 1, LNKB, 0 }, Package(4) { 0x0015FFFF, 2, LNKC, 0 }, Package(4) { 0x0015FFFF, 3, LNKD, 0 },
          Package(4) { 0x0016FFFF, 0, LNKB, 0 }, Package(4) { 0x0016FFFF, 1, LNKC, 0 }, Package(4) { 0x0016FFFF, 2, LNKD, 0 }, Package(4) { 0x0016FFFF, 3, LNKA, 0 },
          Package(4) { 0x0017FFFF, 0, LNKC, 0 }, Package(4) { 0x0017FFFF, 1, LNKD, 0 }, Package(4) { 0x0017FFFF, 2, LNKA, 0 }, Package(4) { 0x0017FFFF, 3, LNKB, 0 },
          Package(4) { 0x0018FFFF, 0, LNKD, 0 }, Package(4) { 0x0018FFFF, 1, LNKA, 0 }, Package(4) { 0x0018FFFF, 2, LNKB, 0 }, Package(4) { 0x0018FFFF, 3, LNKC, 0 },
          Package(4) { 0x0019FFFF, 0, LNKA, 0 }, Package(4) { 0x0019FFFF, 1, LNKB, 0 }, Package(4) { 0x0019FFFF, 2, LNKC, 0 }, Package(4) { 0x0019FFFF, 3, LNKD, 0 },
          Package(4) { 0x001AFFFF, 0, LNKB, 0 }, Package(4) { 0x001AFFFF, 1, LNKC, 0 }, Package(4) { 0x001AFFFF, 2, LNKD, 0 }, Package(4) { 0x001AFFFF, 3, LNKA, 0 },
          Package(4) { 0x001BFFFF, 0, LNKC, 0 }, Package(4) { 0x001BFFFF, 1, LNKD, 0 }, Package(4) { 0x001BFFFF, 2, LNKA, 0 }, Package(4) { 0x001BFFFF, 3, LNKB, 0 },
          Package(4) { 0x001CFFFF, 0, LNKD, 0 }, Package(4) { 0x001CFFFF, 1, LNKA, 0 }, Package(4) { 0x001CFFFF, 2, LNKB, 0 }, Package(4) { 0x001CFFFF, 3, LNKC, 0 },
          Package(4) { 0x001DFFFF, 0, LNKA, 0 }, Package(4) { 0x001DFFFF, 1, LNKB, 0 }, Package(4) { 0x001DFFFF, 2, LNKC, 0 }, Package(4) { 0x001DFFFF, 3, LNKD, 0 },
          Package(4) { 0x001EFFFF, 0, LNKB, 0 }, Package(4) { 0x001EFFFF, 1, LNKC, 0 }, Package(4) { 0x001EFFFF, 2, LNKD, 0 }, Package(4) { 0x001EFFFF, 3, LNKA, 0 },
          Package(4) { 0x001FFFFF, 0, LNKC, 0 }, Package(4) { 0x001FFFFF, 1, LNKD, 0 }, Package(4) { 0x001FFFFF, 2, LNKA, 0 }, Package(4) { 0x001FFFFF, 3, LNKB, 0 },
        })
        Name (_CRS, ResourceTemplate () {
          WordBusNumber (ResourceProducer, MinFixed, MaxFixed, PosDecode,
            0x0000, // Address Space Granularity
            0x0000, // Address Range Minimum
            0x00FF, // Address Range Maximum
            0x0000, // Address Translation Offset
            0x0100, // Address Length
            ,, )
          IO (Decode16,
            0x0CF8, // Address Range Minimum
            0x0CF8, // Address Range Maximum
            0x01, // Address Alignment
            0x08, // Address Length
            )
          WordIO (ResourceProducer, MinFixed, MaxFixed, PosDecode, EntireRange,
            0x0000, // Address Space Granularity
            0x0000, // Address Range Minimum
            0x0CF7, // Address Range Maximum
            0x0000, // Address Translation Offset
            0x0CF8, // Address Length
            ,, , TypeStatic)
          WordIO (ResourceProducer, MinFixed, MaxFixed, PosDecode, EntireRange,
            0x0000, // Address Space Granularity
            0x0D00, // Address Range Minimum
            0xFFFF, // Address Range Maximum
            0x0000, // Address Translation Offset
            0xF300, // Address Length
            ,, , TypeStatic)
          DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
            0x00000000, // Address Space Granularity
            0x000A0000, // Address Range Minimum
            0x000BFFFF, // Address Range Maximum
            0x00000000, // Address Translation Offset
            0x00020000, // Address Length
            ,, , AddressRangeMemory, TypeStatic)
          DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, NonCacheable, ReadWrite,
            0x00000000, // Address Space Granularity
            0xC0000000, // Address Range Minimum
            0xFEBFFFFF, // Address Range Maximum
            0x00000000, // Address Translation Offset
            0x3EC00000, // Address Length
            ,, , AddressRangeMemory, TypeStatic)
        })
      }
      
      Device(HPET) {
        Name(_HID, EISAID("PNP0103"))
        Name(_UID, 0)
        Method (_STA, 0, NotSerialized) {
          Return(0x0F)
        }
        Name(_CRS, ResourceTemplate() {
          DWordMemory(
            ResourceConsumer, PosDecode, MinFixed, MaxFixed,
            NonCacheable, ReadWrite,
            0x00000000,
            0xFED00000,
            0xFED003FF,
            0x00000000,
            0x00000400 /* 1K memory: FED00000 - FED003FF */
          )
        })
      }
    }
    
    Scope(\_SB.PCI0) {
      Device (VGA) {
        Name (_ADR, 0x00020000)
        Method (_S1D, 0, NotSerialized) {
          Return (0x00)
        }
        Method (_S2D, 0, NotSerialized) {
          Return (0x00)
        }
        Method (_S3D, 0, NotSerialized) {
          Return (0x00)
        }
    }
    
    /* PIIX3 ISA bridge */
    Device (ISA) {
      Name (_ADR, 0x00010000)
      
      /* PIIX PCI to ISA irq remapping */
      OperationRegion (P40C, PCI_Config, 0x60, 0x04)
      
      /* Real-time clock */
      Device (RTC) {
        Name (_HID, EisaId ("PNP0B00"))
        Name (_CRS, ResourceTemplate () {
          IO (Decode16, 0x0070, 0x0070, 0x10, 0x02)
          IRQNoFlags () { 8 }
          IO (Decode16, 0x0072, 0x0072, 0x02, 0x06)
        })
      }
      
      /* Keyboard seems to be important for WinXP install */
      Device (KBD) {
        Name (_HID, EisaId ("PNP0303"))
        Method (_STA, 0, NotSerialized) {
          Return (0x0f)
        }
        Method (_CRS, 0, Serialized) {
          Name (TMP, ResourceTemplate () {
            IO (Decode16,
              0x0060, // Address Range Minimum
              0x0060, // Address Range Maximum
              0x01, // Address Alignment
              0x01, // Address Length
            )
            IO (Decode16,
              0x0064, // Address Range Minimum
              0x0064, // Address Range Maximum
              0x01, // Address Alignment
              0x01, // Address Length
            )
            IRQNoFlags () { 1 }
          })
          Return (TMP)
        }
      }
      
      /* PS/2 mouse */
      Device (MOU) {
        Name (_HID, EisaId ("PNP0F13"))
        Method (_STA, 0, NotSerialized) {
          Return (0x0F)
        }
        Method (_CRS, 0, Serialized) {
          Name (TMP, ResourceTemplate () {
            IRQNoFlags () { 12 }
          })
          Return (TMP)
        }
      }
      
      /* PS/2 floppy controller */
      Device (FDC0) {
        Name (_HID, EisaId ("PNP0700"))
        Method (_STA, 0, NotSerialized) {
          Return (0x0F)
        }
        Method (_CRS, 0, Serialized) {
          Name (BUF0, ResourceTemplate () {
            IO (Decode16, 0x03F2, 0x03F2, 0x00, 0x04)
            IO (Decode16, 0x03F7, 0x03F7, 0x00, 0x01)
            IRQNoFlags () { 6 }
            DMA (Compatibility, NotBusMaster, Transfer8) { 2 }
          })
          Return (BUF0)
        }
      }
      
      /* Parallel port */
      Device (LPT) {
        Name (_HID, EisaId ("PNP0400"))
        Method (_STA, 0, NotSerialized) {
          Local0 = \_SB.PCI0.PX13.DRSA
          Local0 &= 0x80000000
          If (Local0 == 0) {
            Return (0x00)
          } Else {
            Return (0x0F)
          }
        }
        Method (_CRS, 0, Serialized) {
          Name (BUF0, ResourceTemplate () {
            IO (Decode16, 0x0378, 0x0378, 0x08, 0x08)
            IRQNoFlags () { 7 }
          })
          Return (BUF0)
        }
      }
      
      /* Serial Ports */
      Device (COM1) {
        Name (_HID, EisaId ("PNP0501"))
        Name (_UID, 0x01)
        Method (_STA, 0, NotSerialized) {
          Local0 = \_SB.PCI0.PX13.DRSC
          Local0 &= 0x08000000
          If (Local0 == 0) {
            Return (0x00)
          } Else {
            Return (0x0F)
          }
        }
        Method (_CRS, 0, Serialized) {
          Name (BUF0, ResourceTemplate () {
            IO (Decode16, 0x03F8, 0x03F8, 0x00, 0x08)
            IRQNoFlags () { 4 }
          })
          Return (BUF0)
        }
      }
      Device (COM2) {
        Name (_HID, EisaId ("PNP0501"))
        Name (_UID, 0x02)
        Method (_STA, 0, NotSerialized) {
          Local0 = \_SB.PCI0.PX13.DRSC
          Local0 &= 0x80000000
          If (Local0 == 0) {
            Return (0x00)
          } Else {
            Return (0x0F)
          }
        }
        Method (_CRS, 0, Serialized) {
          Name (BUF0, ResourceTemplate () {
            IO (Decode16, 0x02F8, 0x02F8, 0x00, 0x08)
            IRQNoFlags () {3}
          })
          Return (BUF0)
        }
      }
    } /* end of Device(ISA) */
    
    /* PIIX4 PM */
    Device (PX13) {
      Name (_ADR, 0x00010003)
      OperationRegion (P13C, PCI_Config, 0x5C, 0x24)
      Field (P13C, DWordAcc, NoLock, Preserve) {
        DRSA, 32,
        DRSB, 32,
        DRSC, 32,
        DRSE, 32,
        DRSF, 32,
        DRSG, 32,
        DRSH, 32,
        DRSI, 32,
        DRSJ, 32
      }
    }
  }  /* end of Scope(\_SB.PCI0) */
  
  /* PCI IRQs */
  Scope(\_SB) {
    Field (\_SB.PCI0.ISA.P40C, ByteAcc, NoLock, Preserve) {
      PRQ0, 8,
      PRQ1, 8,
      PRQ2, 8,
      PRQ3, 8
    }
    Device(LNKA) {
      Name(_HID, EISAID("PNP0C0F")) // PCI interrupt link
      Name(_UID, 1)
      Name(_PRS, ResourceTemplate() {
        IRQ (Level, ActiveLow, Shared)
            { 3,4,5,6,7,9,10,11,12 }
      })
      Method (_STA, 0, NotSerialized) {
        Local0 = 0x0B
        If (0x80 & PRQ0) {
          Local0 = 0x09
        }
        Return (Local0)
      }
      Method (_DIS, 0, NotSerialized) {
        PRQ0 |= 0x80
      }
      Method (_CRS, 0, Serialized) {
        Name (PRR0, ResourceTemplate () {
          IRQ (Level, ActiveLow, Shared) {1}
        })
        CreateWordField (PRR0, 0x01, TMP)
        Local0 = PRQ0
        If (Local0 < 0x80) {
          TMP = One << Local0
        } Else {
          TMP = Zero
        }
        Return (PRR0)
      } 
      Method (_SRS, 1, NotSerialized) {
        CreateWordField (Arg0, 0x01, TMP)
        FindSetRightBit (TMP, Local0)
        Local0--
        PRQ0 = Local0
      }
    }
    
    Device(LNKB) {
      Name(_HID, EISAID("PNP0C0F")) // PCI interrupt link
      Name(_UID, 2)
      Name(_PRS, ResourceTemplate() {
        IRQ (Level, ActiveLow, Shared)
          { 3,4,5,6,7,9,10,11,12 }
      })
      Method (_STA, 0, NotSerialized) {
        Local0 = 0x0B
        If (0x80 & PRQ1) {
          Local0 = 0x09
        }
        Return (Local0)
      }
      Method (_DIS, 0, NotSerialized) {
        PRQ1 |= 0x80
      }
      Method (_CRS, 0, Serialized) {
        Name (PRR0, ResourceTemplate () {
          IRQ (Level, ActiveLow, Shared) { 1 }
        })
        CreateWordField (PRR0, 0x01, TMP)
        Local0 = PRQ1
        If (Local0 < 0x80) {
          TMP = One << Local0
        } Else {
          TMP = Zero
        }
        Return (PRR0)
      }
      Method (_SRS, 1, NotSerialized) {
        CreateWordField (Arg0, 0x01, TMP)
        FindSetRightBit (TMP, Local0)
        Local0--
        PRQ1 = Local0
      }
    }
    
    Device(LNKC) {
      Name(_HID, EISAID("PNP0C0F")) // PCI interrupt link
      Name(_UID, 3)
      Name(_PRS, ResourceTemplate() {
        IRQ (Level, ActiveLow, Shared)
          { 3,4,5,6,7,9,10,11,12 }
      })
      Method (_STA, 0, NotSerialized) {
        Local0 = 0x0B
        If (0x80 & PRQ2) {
          Local0 = 0x09
        }
        Return (Local0)
      }
      Method (_DIS, 0, NotSerialized) {
        PRQ2 |= 0x80
      }
      Method (_CRS, 0, Serialized) {
        Name (PRR0, ResourceTemplate () {
          IRQ (Level, ActiveLow, Shared)
            { 1 }
        })
        CreateWordField (PRR0, 0x01, TMP)
        Local0 = PRQ2
        If (Local0 < 0x80) {
          TMP = One << Local0
        } Else {
          TMP = Zero
        }
        Return (PRR0)
      }
      Method (_SRS, 1, NotSerialized) {
        CreateWordField (Arg0, 0x01, TMP)
        FindSetRightBit (TMP, Local0)
        Local0--
        PRQ2 = Local0
      }
    }
    
    Device(LNKD) {
      Name(_HID, EISAID("PNP0C0F")) // PCI interrupt link
      Name(_UID, 4)
      Name(_PRS, ResourceTemplate() {
        IRQ (Level, ActiveLow, Shared)
          { 3,4,5,6,7,9,10,11,12 }
      })
      Method (_STA, 0, NotSerialized) {
        Local0 = 0x0B
        If (0x80 & PRQ3) {
          Local0 = 0x09
        }
        Return (Local0)
      }
      Method (_DIS, 0, NotSerialized) {
        PRQ3 |= 0x80
      }
      Method (_CRS, 0, Serialized) {
        Name (PRR0, ResourceTemplate () {
          IRQ (Level, ActiveLow, Shared) { 1 }
        })
        CreateWordField (PRR0, 0x01, TMP)
        Local0 = PRQ3
        If (Local0 < 0x80) {
          TMP = One << Local0
        } Else {
          TMP = Zero
        }
        Return (PRR0)
      }
      Method (_SRS, 1, NotSerialized) {
        CreateWordField (Arg0, 0x01, TMP)
        FindSetRightBit (TMP, Local0)
        Local0--
        PRQ3 = Local0
      }
    }
  }  /* end of PCI IRQs */
  
  /* S3 (suspend-to-ram), S4 (suspend-to-disk) and S5 (power-off) type codes:
   * must match piix4 emulation.
   */
  Name (\_S3, Package (0x04) {
    0x01, /* PM1a_CNT.SLP_TYP */
    0x01, /* PM1b_CNT.SLP_TYP */
    Zero, /* reserved */
    Zero /* reserved */
  })
  Name (\_S4, Package (0x04) {
    Zero, /* PM1a_CNT.SLP_TYP */
    Zero, /* PM1b_CNT.SLP_TYP */
    Zero, /* reserved */
    Zero /* reserved */
  })
  Name (\_S5, Package (0x04) {
    Zero, /* PM1a_CNT.SLP_TYP */
    Zero, /* PM1b_CNT.SLP_TYP */
    Zero, /* reserved */
    Zero /* reserved */
  })
}
