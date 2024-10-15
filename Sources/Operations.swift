//
//  Operations.swift
//  lc3vm
//
//  Created by İbrahim Çetin on 9.10.2024.
//

import Foundation

// MARK: - Operation Protocol

@MainActor
protocol Operation {
    static var opcode: Opcode { get }

    static func execute(_ instruction: Instruction) throws
}

extension Operation {
    static func validateOpcode(of instruction: Instruction) throws {
        guard instruction.opcode == opcode else {
            throw LC3VMError.invalidInstruction
        }
    }
}

// MARK: - Instructions

// Implement instructions using this manual: https://www.jmeiners.com/lc3-vm/supplies/lc3-isa.pdf

struct ADD: Operation {
    static let opcode = Opcode.add

    static func execute(_ instruction: Instruction) throws {
        try validateOpcode(of: instruction)

        let newValue: UInt16

        if instruction.isImm5Mode {
            newValue = instruction.srcRegister1.value &+ instruction.imm5
        } else {
            newValue = instruction.srcRegister1.value &+ instruction.srcRegister2.value
        }

        Hardware.updateRegister(instruction.destRegister, with: newValue)

        Hardware.updateConditionFlag(from: instruction.destRegister)
    }
}

struct AND: Operation {
    static let opcode: Opcode = .and

    static func execute(_ instruction: Instruction) throws {
        try validateOpcode(of: instruction)

        let newValue: UInt16

        if instruction.isImm5Mode {
            newValue = instruction.srcRegister1.value & instruction.imm5
        } else {
            newValue = instruction.srcRegister1.value & instruction.srcRegister2.value
        }

        Hardware.updateRegister(instruction.destRegister, with: newValue)

        Hardware.updateConditionFlag(from: instruction.destRegister)
    }
}

struct BR: Operation {
    static let opcode: Opcode = .br

    static func execute(_ instruction: Instruction) throws {
        try validateOpcode(of: instruction)

        var pc = Register.pc
        if (instruction.conditionFlags & Register.cond.value) != 0 {
            pc.value &+= instruction.pcOffset9
        }
    }
}

struct JMP: Operation {
    static let opcode: Opcode = .jmp

    static func execute(_ instruction: Instruction) throws {
        try validateOpcode(of: instruction)

        Hardware.updateRegister(.pc, with: instruction.baseRegister.value)
    }
}

struct JSR: Operation {
    static let opcode: Opcode = .jsr

    static func execute(_ instruction: Instruction) throws {
        try validateOpcode(of: instruction)

        Hardware.updateRegister(.r7, with: Register.pc.value)

        var pc = Register.pc
        if instruction.isPCOffset11Mode {
            pc.value &+= instruction.pcOffset11
        } else {
            pc.value = instruction.baseRegister.value
        }
    }
}

struct LD: Operation {
    static let opcode: Opcode = .ld

    static func execute(_ instruction: Instruction) throws {
        try validateOpcode(of: instruction)

        var destRegister = instruction.destRegister
        let address = Register.pc.value &+ instruction.pcOffset9

        destRegister.value = Hardware.readMemory(at: address)

        Hardware.updateConditionFlag(from: destRegister)
    }
}

struct LDI: Operation {
    static let opcode = Opcode.ldi

    static func execute(_ instruction: Instruction) throws {
        try validateOpcode(of: instruction)

        var destRegister = instruction.destRegister
        let address = Register.pc.value &+ instruction.pcOffset9

        destRegister.value = Hardware.readMemory(at: Hardware.readMemory(at: address))

        Hardware.updateConditionFlag(from: destRegister)
    }
}

struct LDR: Operation {
    static let opcode: Opcode = .ldr

    static func execute(_ instruction: Instruction) throws {
        try validateOpcode(of: instruction)

        var destRegister = instruction.destRegister
        let address = instruction.baseRegister.value &+ instruction.pcOffset6

        destRegister.value = Hardware.readMemory(at: address)

        Hardware.updateConditionFlag(from: destRegister)
    }
}

struct LEA: Operation {
    static let opcode: Opcode = .lea

    static func execute(_ instruction: Instruction) throws {
        try validateOpcode(of: instruction)

        var destRegister = instruction.destRegister
        destRegister.value = Register.pc.value &+ instruction.pcOffset9

        Hardware.updateConditionFlag(from: destRegister)
    }
}

struct NOT: Operation {
    static let opcode: Opcode = .not

    static func execute(_ instruction: Instruction) throws {
        try validateOpcode(of: instruction)

        var destRegister = instruction.destRegister
        destRegister.value = ~instruction.srcRegister1.value

        Hardware.updateConditionFlag(from: destRegister)
    }
}

struct RES: Operation {
    static let opcode: Opcode = .res

    static func execute(_ instruction: Instruction) throws {
        try validateOpcode(of: instruction)
        // Unused, reserved
    }
}

struct RTI: Operation {
    static let opcode: Opcode = .rti

    static func execute(_ instruction: Instruction) throws {
        try validateOpcode(of: instruction)
        // Unused
    }
}

struct ST: Operation {
    static let opcode: Opcode = .st

    static func execute(_ instruction: Instruction) throws {
        try validateOpcode(of: instruction)

        let address = Register.pc.value &+ instruction.pcOffset9
        Hardware.writeMemory(at: address, with: instruction.destRegister.value)
    }
}

struct STI: Operation {
    static let opcode: Opcode = .sti

    static func execute(_ instruction: Instruction) throws {
        try validateOpcode(of: instruction)

        let address1 = Register.pc.value &+ instruction.pcOffset9
        let address2 = Hardware.readMemory(at: address1)
        Hardware.writeMemory(at: address2, with: instruction.destRegister.value)
    }
}

struct STR: Operation {
    static let opcode: Opcode = .str

    static func execute(_ instruction: Instruction) throws {
        try validateOpcode(of: instruction)

        let address = instruction.baseRegister.value &+ instruction.pcOffset6
        Hardware.writeMemory(at: address, with: instruction.destRegister.value)
    }
}

struct TRAP: Operation {
    static let opcode: Opcode = .trap

    static func execute(_ instruction: Instruction) throws {
        try validateOpcode(of: instruction)

        Hardware.updateRegister(.r7, with: Register.pc.value)

        switch instruction.trapCode {
        case .getc:
            getc()
        case .out:
            out()
        case .puts:
            puts()
        case .in:
            self.in()
        case .putsp:
            putsp()
        case .halt:
            halt()
        }
    }

    private static func getc() {
        Hardware.updateRegister(.r0, with: UInt16(getchar()))
        Hardware.updateConditionFlag(from: .r0)
    }

    private static func out() {
        putc(Int32(Register.r0.value), stdout)
        fflush(stdout)
    }

    private static func puts() {
        var address = Register.r0.value
        var value: UInt16

        repeat {
            value = Hardware.readMemory(at: address)
            putc(Int32(value), stdout)

            address += 1
        } while value != 0

        fflush(stdout)
    }

    private static func `in`() {
        print("Enter a character: ", terminator: "")
        let char = getchar()

        putc(char, stdout)
        fflush(stdout)

        Hardware.updateRegister(.r0, with: UInt16(char))
        Hardware.updateConditionFlag(from: .r0)
    }

    private static func putsp() {
        var address = Register.r0.value
        var value: UInt16

        repeat {
            value = Hardware.readMemory(at: address)

            let char1 = value & 0xFF
            putc(Int32(char1), stdout)

            let char2 = value >> 8
            if char2 != 0 {
                putc(Int32(char2), stdout)
            }

            address += 1
        } while value != 0

        fflush(stdout)
    }

    private static func halt() {
        _stdio.puts("HALT")
        fflush(stdout)

        Hardware.isRunning = false
    }
}
