//
//  OperationsTests.swift
//  lc3vm
//
//  Created by İbrahim Çetin on 9.10.2024.
//

@testable import lc3vm
import Testing

// swiftformat:disable numberFormatting

@MainActor
@Suite(.tags(.operation))
struct OperationsTests {
    let hardware = Hardware()

    init() {
        hardware.updateConditionFlag(to: .zro) // Reset condition to zero
        hardware.updateRegister(.pc, with: 0)

        hardware.updateRegister(.r0, with: 5) // 0000 0000 0000 0101
        hardware.updateRegister(.r1, with: 10) // 0000 0000 0000 1010
        hardware.updateRegister(.r2, with: 15) // 0000 0000 0000 1111
    }

    @Test(
        "Test ADD Instruction",
        arguments: [
            (0b0001_001_001_1_00111, 17), // ADD R1 R1 7
            (0b0001_000_000_0_00010, 20), // ADD R0 R0 R2
            (0b0001_010_001_0_00000, 15), // ADD R2 R1 R0
        ]
    )
    func addInstruction(instruction: UInt16, expectedValue: UInt16) throws {
        let instruction = Instruction(rawValue: instruction, hardware: hardware)

        try ADD.execute(instruction)

        #expect(instruction.destRegister.value == expectedValue)
    }

    @Test(
        "Test AND Instruction",
        arguments: [
            (0b0101_001_001_0_00_010, 10), // AND R1 R1 R2
            (0b0101_000_000_1_01111, 5), // AND R0 R0 28
            (0b0101_010_001_0_00_000, 0), // AND R2 R1 R0
        ]
    )
    func andInstruction(instruction: UInt16, expectedValue: UInt16) throws {
        let instruction = Instruction(rawValue: instruction, hardware: hardware)

        try AND.execute(instruction)

        #expect(instruction.destRegister.value == expectedValue)
    }

    @Test(
        "Test BR Instruction",
        arguments: [
            (0b0000_111_000001001, 0b1001), // BRnzp 9
            (0b0000_111_000000000, 0b0000), // BRnzp 0
            (0b0000_111_000000010, 0b0010), // BRnzp 2
        ]
    )
    func brInstruction(instruction: UInt16, expectedAddress: UInt16) throws {
        let instruction = Instruction(rawValue: instruction, hardware: hardware)

        try BR.execute(instruction)

        #expect(hardware.readRegister(.pc) == expectedAddress)
    }

    @Test(
        "Test JMP Instruction",
        arguments: [
            (0b1100_000_000_000000, 5), // JMP R0
            (0b1100_000_001_000000, 10), // JMP R1
            (0b1100_000_010_000000, 15), // JMP R2
        ]
    )
    func jmpInstruction(instruction: UInt16, expectedAddress: UInt16) throws {
        let instruction = Instruction(rawValue: instruction, hardware: hardware)

        try JMP.execute(instruction)

        #expect(hardware.readRegister(.pc) == expectedAddress)
    }

    @Test(
        "Test JSR Instruction",
        arguments: [
            (0b0100_1_00000000010, 0b0000000000000010), // JSR 2
            (0b0100_1_10000000100, 0b1111_1100_0000_0100), // JSR 0xFC04
            (0b0100_0_00_001_000000, 0b1010), // JSRR R0
        ]
    )
    func jsrInstruction(instruction: UInt16, expectedAddress: UInt16) throws {
        let instruction = Instruction(rawValue: instruction, hardware: hardware)

        try JSR.execute(instruction)

        #expect(hardware.readRegister(.pc) == expectedAddress)
    }

    @Test(
        "Test LD Instruction",
        arguments: [
            (0b0010_000_000001110, 42), // LD R0 LABEL, LABEL .FILL 42
            (0b0010_001_000000011, .max), // LD R1 LABEL, LABEL .FILL 65536
            (0b0010_010_111111111, 9999), // LD R2 LABEL, LABEL .FILL 9999
        ]
    )
    func ldInstruction(instruction: UInt16, expectedValue: UInt16) throws {
        // Set the value of the memory address to the expected value
        hardware.writeMemory(at: (instruction & 0x1FF).signExtended(bitCount: 9), with: expectedValue)

        // Create the instruction
        let instruction = Instruction(rawValue: instruction, hardware: hardware)

        // Execute the instruction
        try LD.execute(instruction)

        // Check if the value of the destination register is equal to the expected value
        #expect(instruction.destRegister.value == expectedValue)
    }

    @Test(
        "Test LDI Instruction",
        arguments: [
            (0b1010_000_000000001, 10), // LDI R0 LABEL, LABEL .FILL 10
            (0b1010_001_000000010, 123), // LDI R1 LABEL, LABEL .FILL 65536
            (0b1010_010_111111111, 9999), // LDI R2 LABEL, LABEL .FILL 9999
        ]
    )
    func ldiInstruction(instruction: UInt16, expectedValue: UInt16) throws {
        // Create the instruction
        let instruction = Instruction(rawValue: instruction, hardware: hardware)

        let containerAddress: UInt16 = 0x1234

        hardware.writeMemory(at: instruction.pcOffset9, with: containerAddress)
        hardware.writeMemory(at: containerAddress, with: expectedValue)

        // Execute the instruction
        try LDI.execute(instruction)

        // Check if the value of the destination register is equal to the expected value
        #expect(instruction.destRegister.value == expectedValue)
    }

    @Test(
        "Test LDR Instruction",
        arguments: [
            (0b0110_000_000_000001, 10), // LDR R0 R0 1
            (0b0110_001_001_000010, 15), // LDR R1 R1 2
            (0b0110_010_010_111111, 9999), // LDR R2 R2 -1
        ]
    )
    func ldrInstruction(instruction: UInt16, expectedValue: UInt16) throws {
        // Create the instruction
        let instruction = Instruction(rawValue: instruction, hardware: hardware)

        // Set the value of the memory address to the expected value
        hardware.writeMemory(at: instruction.baseRegister.value &+ instruction.pcOffset6, with: expectedValue)

        // Execute the instruction
        try LDR.execute(instruction)

        // Check if the value of the destination register is equal to the expected value
        #expect(instruction.destRegister.value == expectedValue)
    }

    @Test(
        "Test LEA Instruction",
        arguments: [
            (0b1110_000_000000001, 1), // LEA R0 LABEL
            (0b1110_001_000000010, 2), // LEA R1 LABEL
            (0b1110_010_000000011, 3), // LEA R2 LABEL
        ]
    )
    func leaInstruction(instruction: UInt16, expectedAddress: UInt16) throws {
        // Create the instruction
        let instruction = Instruction(rawValue: instruction, hardware: hardware)

        // Execute the instruction
        try LEA.execute(instruction)

        // Check if the value of the destination register is equal to the expected value
        #expect(instruction.destRegister.value == expectedAddress)
    }

    @Test(
        "Test NOT Instruction",
        arguments: [
            0b1001_000_010_1_11111, // NOT R0 R2
            0b1001_001_001_1_11111, // NOT R1 R1
            0b1001_010_001_1_11111, // NOT R2 R1
        ]
    )
    func notInstruction(instruction: UInt16) throws {
        // Create the instruction
        let instruction = Instruction(rawValue: instruction, hardware: hardware)

        // Calculate the expected value
        let expectedValue = ~instruction.srcRegister1.value

        // Execute the instruction
        try NOT.execute(instruction)

        // Check if the value of the destination register is equal to the expected value
        #expect(instruction.destRegister.value == expectedValue)
    }

    @Test(
        "Test ST Instruction",
        arguments: [
            (0b0011_000_000000001, 5), // ST R0 LABEL
            (0b0011_001_000000010, 10), // ST R1 LABEL
            (0b0011_010_000000011, 15), // ST R2 LABEL
        ]
    )
    func stInstruction(instruction: UInt16, expectedValue: UInt16) throws {
        // Create the instruction
        let instruction = Instruction(rawValue: instruction, hardware: hardware)

        // Execute the instruction
        try ST.execute(instruction)

        // Check if the value of the memory address is equal to the expected value
        #expect(hardware.readMemory(at: instruction.pcOffset9) == expectedValue)
    }

    @Test(
        "Test STI Instruction",
        arguments: [
            0b1011_000_000000001, // STI R0 LABEL
            0b1011_001_000000010, // STI R1 LABEL
            0b1011_010_000000011, // STI R2 LABEL
        ]
    )
    func stiInstruction(instruction: UInt16) throws {
        // Create the instruction
        let instruction = Instruction(rawValue: instruction, hardware: hardware)

        let containerAddress: UInt16 = 0x1234
        hardware.writeMemory(at: instruction.pcOffset9, with: containerAddress)

        // Execute the instruction
        try STI.execute(instruction)

        // Check if the value of the memory address is equal to the expected value
        #expect(hardware.readMemory(at: containerAddress) == instruction.destRegister.value)
    }

    @Test(
        "Test STR Instruction",
        arguments: [
            (0b0111_000_000_000001, 5), // STR R0 R0 LABEL
            (0b0111_001_001_000010, 10), // STR R1 R1 LABEL
            (0b0111_010_010_111111, 15), // STR R2 R2 LABEL
        ]
    )
    func strInstruction(instruction: UInt16, expectedValue: UInt16) throws {
        // Create the instruction
        let instruction = Instruction(rawValue: instruction, hardware: hardware)

        // Execute the instruction
        try STR.execute(instruction)

        // Calculate the memory address to store the value
        let address = instruction.baseRegister.value &+ instruction.pcOffset6

        // Check if the value of the memory address is equal to the expected value
        #expect(hardware.readMemory(at: address) == expectedValue)
    }
}
