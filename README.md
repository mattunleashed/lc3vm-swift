# LC3VM

LC3VM is a Swift implementation of the LC-3 virtual machine, a simple educational computer architecture. This project is a port of the LC-3 VM described in [this guide](https://www.jmeiners.com/lc3-vm/).

## About the LC-3 Computer

The LC-3 (Little Computer 3) is a simulated computer used for educational purposes. It has a simple architecture that makes it ideal for teaching the basics of computer organization and assembly language programming. The LC-3 has a small set of instructions and a simple memory model, making it easy to understand and work with.

## Project Details

This project provides an implementation of the LC-3 virtual machine in Swift. It includes the following components:

- **LC3VM**: The main executable that runs LC-3 programs.
- **LC3VMCore**: A library that provides the core functionality of the LC-3 virtual machine, including instruction decoding, execution, and hardware simulation.

### Features

- Full implementation of the LC-3 instruction set.
- Simulation of LC-3 hardware, including memory and registers.
- Support for loading and executing LC-3 binary files.
- Trap routines for input/output operations.

## Running LC3VM

To run an LC-3 binary file using the LC3VM executable, use the following command:
```bash
swift run LC3VM /path/to/your/lc3/binary/file.obj
```

This will load the specified binary file into the LC-3 virtual machine and start execution.

### Example Programs
You can find example LC-3 assembly programs in the `Programs` directory. To run one of these programs, use the following command:
```bash
swift run LC3VM Programs/<program_name>.obj
```

## Using LC3VMCore in Your Project

You can use the `LC3VMCore` library in your own Swift projects to simulate the LC-3 virtual machine. To do so, add the following dependency to your `Package.swift` file:
```swift
dependencies: [
    .package(url: "https://github.com/ibrahimcetin/lc3vm.git", from: "1.0.0"),
]
```
Then, import the `LC3VMCore` module in your Swift code:
```swift
import LC3VMCore
```

## License
This project is licensed under the MIT License. See the LICENSE file for details.

## Acknowledgments
This project is a port of the LC-3 VM described in [this guide](https://www.jmeiners.com/lc3-vm/). Special thanks to the original author for providing a detailed and educational implementation of the LC-3 virtual machine.
