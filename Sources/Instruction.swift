//
//  Instruction.swift
//  lc3vm
//
//  Created by İbrahim Çetin on 10.10.2024.
//

@MainActor
struct Instruction {
    /// The raw value of the instruction.
    let rawValue: UInt16

    /// The hardware that the instruction will be executed on.
    let hardware: Hardware

    var opcode: Opcode {
        try! Opcode(rawValue: rawValue >> 12)
    }

    var destRegister: Register {
        let type = try! RegisterType(rawValue: (rawValue >> 9) & 0b111)
        return Register(type: type, hardware: hardware)
    }

    var srcRegister1: Register {
        let type = try! RegisterType(rawValue: (rawValue >> 6) & 0b111)
        return Register(type: type, hardware: hardware)
    }

    var srcRegister2: Register {
        let type = try! RegisterType(rawValue: rawValue & 0x7)
        return Register(type: type, hardware: hardware)
    }

    var baseRegister: Register {
        srcRegister1
    }

    var imm5: UInt16 {
        (rawValue & 0x1F).signExtended(bitCount: 5)
    }

    var isImm5Mode: Bool {
        (rawValue >> 5) & 0x1 == 1
    }

    var pcOffset6: UInt16 {
        (rawValue & 0x3F).signExtended(bitCount: 6)
    }

    var pcOffset9: UInt16 {
        (rawValue & 0x1FF).signExtended(bitCount: 9)
    }

    var pcOffset11: UInt16 {
        (rawValue & 0x7FF).signExtended(bitCount: 11)
    }

    var isPCOffset11Mode: Bool {
        (rawValue >> 11) & 0x1 == 1
    }

    var conditionFlags: UInt16 {
        (rawValue >> 9) & 0x7
    }

    var trapCode: TrapCode {
        TrapCode(rawValue: rawValue & 0xFF)!
    }

    init(rawValue: UInt16, hardware: Hardware) {
        self.rawValue = rawValue
        self.hardware = hardware
    }
}

extension UInt16 {
    /// Sign-extends the value to 16 bits.
    func signExtended(bitCount: Int) -> UInt16 {
        if (self >> (bitCount - 1)) & 1 == 1 {
            return self | (0xFFFF << bitCount)
        } else {
            return self
        }
    }
}

// MARK: - Opcodes

/// The LC-3 opcodes.
enum Opcode: Int {
    /// Branch
    case br
    /// Add
    case add
    /// Load
    case ld
    /// Store
    case st
    /// Jump register
    case jsr
    /// Bitwise and
    case and
    /// Load register
    case ldr
    /// Store register
    case str
    /// Return from interrupt (unused)
    case rti
    /// Bitwise not
    case not
    /// Load indirect
    case ldi
    /// Store indirect
    case sti
    /// Jump
    case jmp
    /// Reserved (unused)
    case res
    /// Load effective address
    case lea
    /// Trap
    case trap

    init(rawValue: UInt16) throws {
        guard let opcode = Opcode(rawValue: Int(rawValue)) else {
            throw LC3VMError.invalidOpcode
        }

        self = opcode
    }
}

enum TrapCode: UInt16 {
    /// Get character from keyboard, not echoed onto the terminal.
    case getc = 0x20
    /// Output a character.
    case out = 0x21
    /// Output a word string.
    case puts = 0x22
    /// Get character from keyboard, echoed onto the terminal.
    case `in` = 0x23
    /// Output a byte string.
    case putsp = 0x24
    /// Halt the program.
    case halt = 0x25
}
