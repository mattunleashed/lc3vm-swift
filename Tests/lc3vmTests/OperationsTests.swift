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

        hardware.updateRegister(.r0, with: 5)  // 0000 0000 0000 0101
        hardware.updateRegister(.r1, with: 10) // 0000 0000 0000 1010
        hardware.updateRegister(.r2, with: 15) // 0000 0000 0000 1111
    }

    @Test(
        "Test ADD Instruction",
        arguments: [
            (0b0001_001_001_1_00111, 17), // ADD R1 R1 7
            (0b0001_000_000_0_00010, 20), // ADD R0 R0 R2
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
            (0b0000_111_000001001, 0b1001),
        ]
    )
    func brInstruction(instruction: UInt16, expectedAddress: UInt16) throws {
        let instruction = Instruction(rawValue: instruction, hardware: hardware)

        try BR.execute(instruction)

        #expect(hardware.readRegister(.pc) == expectedAddress)
    }
}
