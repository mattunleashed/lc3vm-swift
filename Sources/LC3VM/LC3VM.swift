//
//  LC3VM.swift
//  lc3vm
//
//  Created by İbrahim Çetin on 9.10.2024.
//

import ArgumentParser
import Foundation
import LC3VMCore

/// The LC-3 virtual machine.
@main
@available(macOS 12, *) // https://forums.swift.org/t/asyncparsablecommand-doesnt-work/71300
@MainActor
struct LC3VM: AsyncParsableCommand {
    @Argument(help: "The path to the LC3 binary file to run.", transform: URL.init(fileURLWithPath:))
    var binary: URL

    func run() async throws {
        // Create the LC-3 hardware
        let hardware = Hardware()

        // Read the binary file and load it into memory
        try hardware.readImage(binary)

        // Set up the signal handler
        signal(SIGINT) { handle_interrupt($0) }
        // Disable input buffering
        disable_input_buffering()

        // Start the LC-3 machine
        hardware.isRunning = true

        while hardware.isRunning {
            let instruction = hardware.readNextInstruction()

            switch try instruction.opcode {
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

        // Restore input buffering
        restore_input_buffering()
    }
}
