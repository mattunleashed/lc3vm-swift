//
//  InstructionTests.swift
//  lc3vm
//
//  Created by İbrahim Çetin on 9.10.2024.
//

import Testing
@testable import lc3vm

@MainActor
@Suite(.tags(.instruction), .serialized)
struct InstructionTests {
    init() {
        Hardware.updateConditionFlag(to: .zro) // Reset condition to zero
        Hardware.updateRegister(.pc, with: 0)

        Hardware.updateRegister(.r0, with: 0)
        Hardware.updateRegister(.r1, with: 34) // 0000 0000 0010 0010
        Hardware.updateRegister(.r2, with: 58) // 0000 0000 0011 1010
    }

    @Test(
        "Test ADD Instruction",
        arguments: [
            (0b0001_001_001_1_00111, 41), // ADD R1 R1 7
            (0b0001_000_000_0_00010, 58), // ADD R0 R0 R2
        ]
    )
    func addInstruction(instruction: UInt16, expectedValue: UInt16) throws {
        let instruction = Instruction(rawValue: instruction)

        try ADD.execute(instruction)

        #expect(instruction.destRegister.value == expectedValue)
    }

    @Test(
        "Test AND Instruction",
        arguments: [
            (0b0101_001_001_0_00_010, 34), // AND R1 R1 R2
            (0b0101_000_000_1_11011, 0), // AND R0 R0 27
        ]
    )
    func andInstruction(instruction: UInt16, expectedValue: UInt16) throws {
        let instruction = Instruction(rawValue: instruction)

        try AND.execute(instruction)

        #expect(instruction.destRegister.value == expectedValue)
    }

    @Test(
        "Test BR Instruction",
        arguments: [
            (0b0000_111_000001001, 0b1001)
        ]
    )
    func brInstruction(instruction: UInt16, expectedAddress: UInt16) throws {
        let instruction = Instruction(rawValue: instruction)

        try BR.execute(instruction)

        #expect(Register.pc.value == expectedAddress)
    }
}
