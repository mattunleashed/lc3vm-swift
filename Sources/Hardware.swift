//
//  Hardware.swift
//  lc3vm
//
//  Created by İbrahim Çetin on 9.10.2024.
//

import Foundation

@MainActor
enum Hardware {
    // 65536 locations, 128KB of memory
    static var memory = [UInt16](repeating: 0, count: Constant.memorySize)

    // 10 general-purpose registers
    static var registers = [UInt16](repeating: 0, count: Constant.registerCount)

    // Indicates whether the hardware is running
    static var isRunning = false

    // Updates the value of a register
    static func updateRegister(_ register: Register, with value: UInt16) {
        registers[register.rawValue] = value
    }

    static func readRegister(_ register: Register) -> UInt16 {
        return registers[register.rawValue]
    }

    static func readConditionFlag() -> ConditionFlag {
        ConditionFlag(rawValue: Register.cond.value)!
    }

    static func updateConditionFlag(to value: ConditionFlag) {
        updateRegister(.cond, with: value.rawValue)
    }

    static func updateConditionFlag(from register: Register) {
        let value = registers[register.rawValue]

        let condition: ConditionFlag = if value == 0 {
            .zro
        } else if (value >> 15) & 1 == 1 { // a 1 in the left-most bit indicates negative
            .neg
        } else {
            .pos
        }

        updateConditionFlag(to: condition)
    }

    static func readMemory(at address: UInt16) -> UInt16 {
        if address == MemoryRegister.kbsr.rawValue {
            if check_key() {
                Hardware.writeMemory(at: MemoryRegister.kbsr.rawValue, with: 1 << 15)
                Hardware.writeMemory(at: MemoryRegister.kbdr.rawValue, with: UInt16(getchar()))
            } else {
                Hardware.writeMemory(at: MemoryRegister.kbsr.rawValue, with: 0)
            }
        }

        return memory[Int(address)]
    }

    static func writeMemory(at address: UInt16, with value: UInt16) {
        memory[Int(address)] = value
    }

    static func readNextInstruction() -> Instruction {
        let instruction = readMemory(at: Register.pc.value)
        registers[Register.pc.rawValue] &+= 1

        return Instruction(rawValue: instruction)
    }

    static func readImage(_ path: URL) throws {
        guard let file = fopen(path.path, "rb") else {
            throw LC3VMError.unableToReadImageFile
        }

        readImageFile(file)

        fclose(file)
    }

    private static func readImageFile(_ file: UnsafeMutablePointer<FILE>) {
        /* the origin tells us where in memory to place the image */
        var origin: UInt16 = 0
        fread(&origin, MemoryLayout.size(ofValue: origin), 1, file)
        origin = swap16(origin)

        /* we know the maximum file size so we only need one fread */
        let maxRead = Constant.memorySize - Int(origin)

        memory.withUnsafeBufferPointer { buffer in
            var pointer = UnsafeMutableRawPointer(mutating: buffer.baseAddress!.advanced(by: Int(origin)))

            var readCount = fread(pointer, MemoryLayout<UInt16>.stride, Int(maxRead), file)

            while readCount > 0 {
                pointer.storeBytes(of: swap16(pointer.load(as: UInt16.self)), as: UInt16.self)

                pointer = pointer.advanced(by: MemoryLayout<UInt16>.stride)
                readCount -= 1
            }
        }
    }

    private static func swap16(_ x: UInt16) -> UInt16 {
        (x << 8) | (x >> 8)
    }
}

@MainActor
enum Register: Int {
    /// General-purpose register.
    case r0, r1, r2, r3, r4, r5, r6, r7
    /// Program counter.
    case pc
    /// Condition flag register.
    case cond

    init(rawValue: UInt16) throws {
        guard let register = Register(rawValue: Int(rawValue)) else {
            throw LC3VMError.invalidRegister
        }

        self = register
    }

    var value: UInt16 {
        get {
            return Hardware.readRegister(self)
        }

        set {
            Hardware.updateRegister(self, with: newValue)
        }
    }
}

enum MemoryRegister: UInt16 {
    /// Keyboard status.
    case kbsr = 0xFE00
    /// Keyboard data.
    case kbdr = 0xFE02
}

enum ConditionFlag: UInt16 {
    /// Positive
    case pos = 0b001
    /// Zero
    case zro = 0b010
    /// Negative
    case neg = 0b100
}
