//
//  lc3vm.swift
//  lc3vm
//
//  Created by İbrahim Çetin on 9.10.2024.
//

import ArgumentParser
import Foundation

/// The LC-3 virtual machine.
@main
@available(macOS 12, *) // https://forums.swift.org/t/asyncparsablecommand-doesnt-work/71300
@MainActor
struct LC3VM: AsyncParsableCommand {
    @Argument(help: "The path to the LC3 binary file to run.", transform: URL.init(fileURLWithPath:))
    var binary: URL

    func run() async throws {
        // Read the binary file and load it into memory
        try Hardware.readImage(binary)

        signal(SIGINT) { handle_interrupt($0) }
        disable_input_buffering()

        // Set condition register to zero which value is 010 (not 000)
        Hardware.updateConditionFlag(to: .zro)

        // Set the program counter to the default starting location
        Hardware.updateRegister(.pc, with: Constant.pcStart)

        Hardware.isRunning = true

        while Hardware.isRunning {
            let instruction = Hardware.readNextInstruction()

            switch instruction.opcode {
            case .br:
                try BR.execute(instruction)
            case .add:
                try ADD.execute(instruction)
            case .ld:
                try LD.execute(instruction)
            case .st:
                try ST.execute(instruction)
            case .jsr:
                try JSR.execute(instruction)
            case .and:
                try AND.execute(instruction)
            case .ldr:
                try LDR.execute(instruction)
            case .str:
                try STR.execute(instruction)
            case .rti:
                try RTI.execute(instruction)
            case .not:
                try NOT.execute(instruction)
            case .ldi:
                try LDI.execute(instruction)
            case .sti:
                try STI.execute(instruction)
            case .jmp:
                try JMP.execute(instruction)
            case .res:
                try RES.execute(instruction)
            case .lea:
                try LEA.execute(instruction)
            case .trap:
                try TRAP.execute(instruction)
            }
        }

        restore_input_buffering()
    }
}

/// The error type for the LC3 virtual machine.
enum LC3VMError: Error {
    case badOpcode
    case invalidInstruction
    case invalidRegister
    case invalidOpcode
    case unableToReadImageFile
}

/// The LC-3 constant values.
enum Constant {
    static let memorySize = 1 << 16
    static let registerCount = 10
    static let pcStart: UInt16 = 0x3000 // Default program counter location
}
