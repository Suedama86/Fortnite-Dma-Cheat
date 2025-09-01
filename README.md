# Fortnite-Dma-Cheat

A semi-unfinished Fortnite DMA cheat project with comprehensive setup documentation for modern virtualized environments.

## Overview

This project implements memory introspection and analysis capabilities for Fortnite using Direct Memory Access (DMA) techniques. The project supports both traditional hardware-based DMA approaches and modern virtualized environments using memflow backend.

## Key Features

- **Multi-Backend Support**: Compatible with both traditional MemProcFS/VMMDLL and modern memflow backends
- **Virtualization Ready**: Optimized for Proxmox/QEMU environments with Windows guest VMs
- **GitHub Copilot Enhanced**: Comprehensive AI-assisted development workflow
- **Performance Optimized**: Efficient memory scanning and pattern matching algorithms
- **Cross-Platform**: Supports both Windows and Linux development environments

## Documentation

### 📚 Comprehensive Setup Guides

- **[Proxmox + Windows VM Setup Guide](PROXMOX_SETUP_GUIDE.md)** - Complete guide for setting up Proxmox host with Windows guest VM for DMA operations
- **[Memflow Backend Integration](MEMFLOW_INTEGRATION.md)** - Detailed implementation guide for memflow backend with code examples

### 🛠️ Quick Start

1. **Traditional Setup**: Follow the original hardware-based setup (requires physical DMA hardware)
2. **Virtualized Setup**: Use the [Proxmox Setup Guide](PROXMOX_SETUP_GUIDE.md) for a modern virtualized approach
3. **Development**: Integrate [GitHub Copilot](PROXMOX_SETUP_GUIDE.md#github-copilot-integration) for enhanced development experience

## Project Status

This project was initially paused due to time constraints, but comprehensive documentation has been added to make setup and development more accessible. The codebase includes:

- Core DMA memory access functionality
- Entity scanning and tracking systems
- Rendering and overlay capabilities
- Input simulation and control systems

## Requirements

### Traditional Setup
- DMA-capable hardware (FPGA cards, etc.)
- MemProcFS library with CR3 fixes
- Windows target system
- Visual Studio 2019/2022

### Virtualized Setup (Recommended)
- Proxmox VE 8.0+ on bare metal
- 16GB+ RAM (32GB+ recommended)
- CPU with VT-x/AMD-V support
- Windows 10/11 guest VM
- Memflow framework

## Building

### Visual Studio (Windows)
```cmd
# Open Solution.sln in Visual Studio
# Select Release configuration, x64 platform
# Build -> Build Solution
```

### CMake (Cross-platform)
```bash
mkdir build && cd build
cmake ..
make -j$(nproc)
```

## Legal Notice

⚠️ **Important**: This project is for educational and research purposes only. Users must comply with:
- Game terms of service
- Local and international laws
- Anti-cheat software policies
- Intellectual property rights

## Contributing

Contributions are welcome! Please:
1. Follow the GitHub Copilot integration guidelines in the documentation
2. Use the established code patterns and architecture
3. Test both traditional and memflow backends
4. Update documentation for any new features

## Future Plans

When development resumes, planned improvements include:
- Enhanced performance optimizations
- Additional game support
- Improved detection evasion
- Advanced pattern recognition algorithms
- Real-time configuration management

## Support

For setup assistance:
1. Check the comprehensive documentation first
2. Review the troubleshooting sections
3. Ensure all prerequisites are met
4. Test with the provided examples

---

*Note: Some files from the memprocfs library and CR3 fixes need to be included separately. The provided documentation guides you through obtaining and configuring these dependencies.*