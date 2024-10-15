//
//  CHelpers.swift
//  lc3vm
//
//  Created by İbrahim Çetin on 11.10.2024.
//

import Foundation

// swiftlint:disable all

@MainActor
var original_tio = termios()

@MainActor
func disable_input_buffering() {
    tcgetattr(STDIN_FILENO, &original_tio)
    var new_tio = original_tio
    new_tio.c_lflag = UInt(Int32(new_tio.c_lflag) & ~ICANON & ~ECHO)
    tcsetattr(STDIN_FILENO, TCSANOW, &new_tio)
}

@MainActor
func restore_input_buffering() {
    tcsetattr(STDIN_FILENO, TCSANOW, &original_tio)
}

@MainActor
func handle_interrupt(_: Int32) {
    restore_input_buffering()
    print("")
    exit(-2)
}

func check_key() -> Bool {
    var readfds = fd_set()
    readfds.fdZero()
    readfds.fdSet(fd: STDIN_FILENO)

    var timeout = timeval(tv_sec: 0, tv_usec: 0)
    return select(1, &readfds, nil, nil, &timeout) != 0
}

// Ports the FD_ZERO and FD_SET C macros in Darwin to Swift.
// https://github.com/apple/darwin-xnu/blob/master/bsd/sys/_types/_fd_def.h
// This is not portable to Linux.
extension fd_set {
    // FD_ZERO(self)
    mutating func fdZero() {
        bzero(&fds_bits, MemoryLayout.size(ofValue: fds_bits))
    }

    // FD_SET(fd, self)
    mutating func fdSet(fd: Int32) {
        let __DARWIN_NFDBITS = Int32(MemoryLayout<Int32>.size) * __DARWIN_NBBY
        let bits = UnsafeMutableBufferPointer(start: &fds_bits.0, count: 32)
        bits[Int(CUnsignedLong(fd) / CUnsignedLong(__DARWIN_NFDBITS))] |= __int32_t(
            CUnsignedLong(1) << CUnsignedLong(fd % __DARWIN_NFDBITS)
        )
    }
}
