//
//  Instruction.swift
//  lc3vm
//
//  Created by İbrahim Çetin on 10.10.2024.
//

/// The LC-3 instruction.
///
/// The LC-3 instruction is a 16-bit value that contains the opcode and the operands of the instruction.
///
/// The instruction is divided into multiple fields that represent different parts of the instruction.
///
/// To simplify the decoding of the instruction, the `Instruction` struct provides computed properties
/// that extract the opcode, registers, immediate values and pc offsets etc. from the instruction.
/// You can use these properties to decode the instruction and execute the corresponding operation.
@MainActor
public struct Instruction {
    /// The raw value of the instruction.
    public let rawValue: UInt16

    /// The hardware that the instruction will be executed on.
    public let hardware: Hardware

    /// The opcode of the instruction.
    public var opcode: Opcode {
        get throws {
            try Opcode(rawValue: rawValue >> 12)
        }
    }

    /// The destination register of the instruction.
    public var destRegister: Register {
        get throws {
            let type = try RegisterType(rawValue: (rawValue >> 9) & 0b111)
            return Register(type: type, hardware: hardware)
        }
    }

    /// The source register of the instruction.
    ///
    /// It is the same as the destination register for some instructions
    /// that do not have a destination register. (e.g. ST)
    public var srcRegister: Register {
        get throws {
            try destRegister
        }
    }

    /// The source register 1 of the instruction.
    public var srcRegister1: Register {
        get throws {
            let type = try RegisterType(rawValue: (rawValue >> 6) & 0b111)
            return Register(type: type, hardware: hardware)
        }
    }

    /// The source register 2 of the instruction.
    public var srcRegister2: Register {
        get throws {
            let type = try RegisterType(rawValue: rawValue & 0x7)
            return Register(type: type, hardware: hardware)
        }
    }

    /// The base register of the instruction.
    public var baseRegister: Register {
        get throws {
            try srcRegister1
        }
    }

    /// The 5 bits immediate value of the instruction.
    public var imm5: UInt16 {
        (rawValue & 0x1F).signExtended(bitCount: 5)
    }

    /// The flag that indicates if the instruction is in immediate mode.
    public var isImm5Mode: Bool {
        (rawValue >> 5) & 0x1 == 1
    }

    /// The 6 bits PC offset of the instruction.
    public var pcOffset6: UInt16 {
        (rawValue & 0x3F).signExtended(bitCount: 6)
    }

    /// The 9 bits PC offset of the instruction.
    public var pcOffset9: UInt16 {
        (rawValue & 0x1FF).signExtended(bitCount: 9)
    }

    /// The 11 bits PC offset of the instruction.
    public var pcOffset11: UInt16 {
        (rawValue & 0x7FF).signExtended(bitCount: 11)
    }

    /// The flag that indicates if the instruction is in PC offset 11 mode.
    public var isPCOffset11Mode: Bool {
        (rawValue >> 11) & 0x1 == 1
    }

    /// The condition flags of the instruction.
    public var conditionFlags: UInt16 {
        (rawValue >> 9) & 0x7
    }

    /// The trap code of the instruction.
    public var trapCode: TrapCode {
        TrapCode(rawValue: rawValue & 0xFF)!
    }

    public init(rawValue: UInt16, hardware: Hardware) {
        self.rawValue = rawValue
        self.hardware = hardware
    }
}

public extension UInt16 {
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
public enum Opcode: Int {
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

    public init(rawValue: UInt16) throws {
        guard let opcode = Opcode(rawValue: Int(rawValue)) else {
            throw LC3VMError.invalidOpcode
        }

        self = opcode
    }
}

public enum TrapCode: UInt16 {
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
