//
//  Operations.swift
//  lc3vm
//
//  Created by İbrahim Çetin on 9.10.2024.
//

import Foundation

// MARK: - Operation Protocol

/// Represents an operation that can be executed by the LC-3 virtual machine.
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

// MARK: - Operations

// Implement operations using this manual: https://www.jmeiners.com/lc3-vm/supplies/lc3-isa.pdf

/// Represents the ADD instruction.
/// Adds the values of two registers or a register and an immediate value.
/// - If the instruction is in immediate mode, the value of the source register is added to the immediate value.
/// - If the instruction is in register mode, the values of the two source registers are added.
/// The result is stored in the destination register, and the condition flags are updated based on the result.
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

        let hardware: Hardware = instruction.hardware

        // Update the destination register with the new value
        hardware.updateRegister(instruction.destRegister.type, with: newValue)
        // Update the condition flag based on the new value
        hardware.updateConditionFlag(from: instruction.destRegister.type)
    }
}

/// Represents the AND instruction.
/// Performs a bitwise AND on the values of two registers or a register and an immediate value.
/// - If the instruction is in immediate mode, the value of the source register is ANDed with the immediate value.
/// - If the instruction is in register mode, the values of the two source registers are ANDed.
/// The result is stored in the destination register, and the condition flags are updated based on the result.
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

        let hardware: Hardware = instruction.hardware

        // Update the destination register with the new value
        hardware.updateRegister(instruction.destRegister.type, with: newValue)
        // Update the condition flag based on the new value
        hardware.updateConditionFlag(from: instruction.destRegister.type)
    }
}

/// Represents the BR instruction.
/// Branches to a new location if the condition flags match.
/// - The program counter is updated with the offset if the condition flags match the specified condition.
/// This allows for conditional branching in the program.
struct BR: Operation {
    static let opcode: Opcode = .br

    static func execute(_ instruction: Instruction) throws {
        try validateOpcode(of: instruction)

        // Get the registers
        var pc = Register(type: .pc, hardware: instruction.hardware)
        let cond = Register(type: .cond, hardware: instruction.hardware)

        // Check if the condition flags match
        if (instruction.conditionFlags & cond.value) != 0 {
            pc.value &+= instruction.pcOffset9
        }
    }
}

/// Represents the JMP instruction.
/// Jumps to the address contained in a base register.
/// - The program counter is updated with the value of the base register.
/// This allows for unconditional jumps in the program.
struct JMP: Operation {
    static let opcode: Opcode = .jmp

    static func execute(_ instruction: Instruction) throws {
        try validateOpcode(of: instruction)

        let hardware: Hardware = instruction.hardware

        // Update the program counter with the value of the base register
        hardware.updateRegister(.pc, with: instruction.baseRegister.value)
    }
}

/// Represents the JSR instruction.
/// Jumps to a subroutine.
/// - The return address is stored in register R7.
/// - The program counter is updated with the offset or the value of the base register.
/// This allows for calling subroutines and returning to the caller.
struct JSR: Operation {
    static let opcode: Opcode = .jsr

    static func execute(_ instruction: Instruction) throws {
        try validateOpcode(of: instruction)

        let hardware: Hardware = instruction.hardware

        // Update the return address
        hardware.updateRegister(.r7, with: hardware.readRegister(.pc))

        // Update the program counter
        var pc = Register(type: .pc, hardware: hardware)
        if instruction.isPCOffset11Mode {
            pc.value &+= instruction.pcOffset11
        } else {
            pc.value = instruction.baseRegister.value
        }
    }
}

/// Represents the LD instruction.
/// Loads a value from memory into a register.
/// - The value at the memory address specified by the program counter and offset is loaded into the destination register.
/// The condition flags are updated based on the loaded value.
struct LD: Operation {
    static let opcode: Opcode = .ld

    static func execute(_ instruction: Instruction) throws {
        try validateOpcode(of: instruction)

        let hardware = instruction.hardware

        var destRegister = instruction.destRegister
        let address = hardware.readRegister(.pc) &+ instruction.pcOffset9

        destRegister.value = hardware.readMemory(at: address)

        hardware.updateConditionFlag(from: destRegister.type)
    }
}

/// Represents the LDI instruction.
/// Loads a value indirectly from memory into a register.
/// - The value stored in memory at this computed address is the address of the data to be loaded into the destination register.
/// The condition flags are updated based on the loaded value.
struct LDI: Operation {
    static let opcode = Opcode.ldi

    static func execute(_ instruction: Instruction) throws {
        try validateOpcode(of: instruction)

        let hardware = instruction.hardware

        // Get the destination register and the new address
        var destRegister = instruction.destRegister
        let address = hardware.readRegister(.pc) &+ instruction.pcOffset9

        // Read the value from the memory address stored in the memory address
        destRegister.value = hardware.readMemory(at: hardware.readMemory(at: address))

        // Update the condition flag based on the new value
        hardware.updateConditionFlag(from: destRegister.type)
    }
}

/// Represents the LDR instruction.
/// Loads a value from memory into a register using a base register and an offset.
/// - The value at the memory address specified by the base register and offset is loaded into the destination register.
/// The condition flags are updated based on the loaded value.
struct LDR: Operation {
    static let opcode: Opcode = .ldr

    static func execute(_ instruction: Instruction) throws {
        try validateOpcode(of: instruction)

        let hardware = instruction.hardware

        // Get the destination register and the new address
        var destRegister = instruction.destRegister
        let address = instruction.baseRegister.value &+ instruction.pcOffset6

        // Read the value from the memory address
        destRegister.value = hardware.readMemory(at: address)

        // Update the condition flag based on the new value
        hardware.updateConditionFlag(from: destRegister.type)
    }
}

/// Represents the LEA instruction.
/// Loads the effective address into a register.
/// - The effective address specified by the program counter and offset, the address, is loaded into the destination register.
/// The condition flags are updated based on the loaded value.
struct LEA: Operation {
    static let opcode: Opcode = .lea

    static func execute(_ instruction: Instruction) throws {
        try validateOpcode(of: instruction)

        let hardware = instruction.hardware

        var destRegister = instruction.destRegister
        destRegister.value = hardware.readRegister(.pc) &+ instruction.pcOffset9

        hardware.updateConditionFlag(from: destRegister.type)
    }
}

/// Represents the NOT instruction.
/// Performs a bitwise NOT on the value of a register.
/// - The value of the source register is bitwise negated and stored in the destination register.
/// The condition flags are updated based on the result.
struct NOT: Operation {
    static let opcode: Opcode = .not

    static func execute(_ instruction: Instruction) throws {
        try validateOpcode(of: instruction)

        var destRegister = instruction.destRegister
        destRegister.value = ~instruction.srcRegister1.value

        let hardware = instruction.hardware
        hardware.updateConditionFlag(from: destRegister.type)
    }
}

/// Represents the RES instruction.
/// Reserved for future use.
/// - This instruction is currently unused and reserved for future use.
struct RES: Operation {
    static let opcode: Opcode = .res

    static func execute(_ instruction: Instruction) throws {
        try validateOpcode(of: instruction)
        // Unused, reserved
    }
}

/// Represents the RTI instruction.
/// Returns from an interrupt.
/// - This instruction is currently unused.
struct RTI: Operation {
    static let opcode: Opcode = .rti

    static func execute(_ instruction: Instruction) throws {
        try validateOpcode(of: instruction)
        // Unused
    }
}

/// Represents the ST instruction.
/// Stores a value from a register into memory.
/// - The value of the destination register is stored at the memory address specified by the program counter and offset.
struct ST: Operation {
    static let opcode: Opcode = .st

    static func execute(_ instruction: Instruction) throws {
        try validateOpcode(of: instruction)

        let hardware = instruction.hardware

        let address = hardware.readRegister(.pc) &+ instruction.pcOffset9
        hardware.writeMemory(at: address, with: instruction.destRegister.value)
    }
}

/// Represents the STI instruction.
/// Stores a value indirectly from a register into memory.
/// - The value in the source register is stored at the memory address found at another memory address.
struct STI: Operation {
    static let opcode: Opcode = .sti

    static func execute(_ instruction: Instruction) throws {
        try validateOpcode(of: instruction)

        let hardware = instruction.hardware

        let address1 = hardware.readRegister(.pc) &+ instruction.pcOffset9
        let address2 = hardware.readMemory(at: address1)

        // Store the value in the memory address stored in the memory address
        hardware.writeMemory(at: address2, with: instruction.destRegister.value)
    }
}

/// Represents the STR instruction.
/// Stores a value from a register into memory using a base register and an offset.
/// - The value of the destination register is stored at the memory address specified by the base register and offset.
struct STR: Operation {
    static let opcode: Opcode = .str

    static func execute(_ instruction: Instruction) throws {
        try validateOpcode(of: instruction)

        let hardware = instruction.hardware

        let address = instruction.baseRegister.value &+ instruction.pcOffset6
        // Store the register value in the memory address
        hardware.writeMemory(at: address, with: instruction.destRegister.value)
    }
}

/// Represents the TRAP instruction.
/// Executes a trap routine.
/// - The return address is stored in register R7.
/// - The trap routine specified by the trap code is executed.
struct TRAP: Operation {
    static let opcode: Opcode = .trap

    static func execute(_ instruction: Instruction) throws {
        try validateOpcode(of: instruction)

        let hardware = instruction.hardware

        // Save the return address
        hardware.updateRegister(.r7, with: hardware.readRegister(.pc))

        switch instruction.trapCode {
        case .getc:
            getc(on: hardware)
        case .out:
            out(on: hardware)
        case .puts:
            puts(on: hardware)
        case .in:
            self.in(on: hardware)
        case .putsp:
            putsp(on: hardware)
        case .halt:
            halt(on: hardware)
        }
    }

    private static func getc(on hardware: Hardware) {
        hardware.updateRegister(.r0, with: UInt16(getchar()))
        hardware.updateConditionFlag(from: .r0)
    }

    private static func out(on hardware: Hardware) {
        let r0 = Register(type: .r0, hardware: hardware)

        putc(Int32(r0.value), stdout)
        fflush(stdout)
    }

    private static func puts(on hardware: Hardware) {
        var address = hardware.readRegister(.r0)
        var value: UInt16

        repeat {
            value = hardware.readMemory(at: address)
            putc(Int32(value), stdout)

            address += 1
        } while value != 0

        fflush(stdout)
    }

    private static func `in`(on hardware: Hardware) {
        print("Enter a character: ", terminator: "")
        let char = getchar()

        putc(char, stdout)
        fflush(stdout)

        hardware.updateRegister(.r0, with: UInt16(char))
        hardware.updateConditionFlag(from: .r0)
    }

    private static func putsp(on hardware: Hardware) {
        var address = hardware.readRegister(.r0)
        var value: UInt16

        repeat {
            value = hardware.readMemory(at: address)

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

    private static func halt(on hardware: Hardware) {
        _stdio.puts("HALT")
        fflush(stdout)

        // Shutdown the hardware
        let hardware = hardware
        hardware.isRunning = false
    }
}
