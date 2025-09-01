cmake_minimum_required(VERSION 3.16)
project(FortniteMemflowDMA VERSION 1.0.0 LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Build type
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

# Options
option(USE_MEMFLOW_BACKEND "Enable memflow backend support" ON)
option(USE_VMMDLL_BACKEND "Enable VMMDLL backend support" ON)
option(BUILD_TESTS "Build unit tests" OFF)
option(ENABLE_COPILOT_FEATURES "Enable GitHub Copilot enhanced features" ON)

# Find packages
find_package(PkgConfig)

# Try to find memflow if enabled
if(USE_MEMFLOW_BACKEND AND PkgConfig_FOUND)
    pkg_check_modules(MEMFLOW memflow)
    if(MEMFLOW_FOUND)
        message(STATUS "Found memflow library")
        add_definitions(-DUSE_MEMFLOW_BACKEND)
    else()
        message(WARNING "Memflow library not found, disabling memflow backend")
        set(USE_MEMFLOW_BACKEND OFF)
    endif()
endif()

# Platform detection
if(WIN32)
    add_definitions(-DPLATFORM_WINDOWS)
    set(PLATFORM_NAME "Windows")
elseif(UNIX AND NOT APPLE)
    add_definitions(-DPLATFORM_LINUX)
    set(PLATFORM_NAME "Linux")
else()
    message(FATAL_ERROR "Unsupported platform")
endif()

message(STATUS "Building for ${PLATFORM_NAME}")
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")

# Include directories
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/fortnite-dma-raw
    ${CMAKE_CURRENT_SOURCE_DIR}/fortnite-dma-raw/dependencies
    ${CMAKE_CURRENT_SOURCE_DIR}/fortnite-dma-raw/dependencies/memprocfs-cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/fortnite-dma-raw/dependencies/imgui
)

# Add memflow include directories if available
if(USE_MEMFLOW_BACKEND AND MEMFLOW_FOUND)
    include_directories(${MEMFLOW_INCLUDE_DIRS})
    link_directories(${MEMFLOW_LIBRARY_DIRS})
endif()

# Source files
file(GLOB_RECURSE CORE_SOURCES
    "fortnite-dma-raw/*.cpp"
    "fortnite-dma-raw/*.h"
)

file(GLOB_RECURSE MEMPROCFS_SOURCES
    "fortnite-dma-raw/dependencies/memprocfs-cpp/*.cpp"
    "fortnite-dma-raw/dependencies/memprocfs-cpp/*.h"
)

file(GLOB_RECURSE IMGUI_SOURCES
    "fortnite-dma-raw/dependencies/imgui/*.cpp"
    "fortnite-dma-raw/dependencies/imgui/*.h"
)

# Exclude main.cpp from core sources for library build
list(REMOVE_ITEM CORE_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/fortnite-dma-raw/main.cpp")

# Create library for core functionality
add_library(fortnite_dma_core STATIC
    ${CORE_SOURCES}
    ${MEMPROCFS_SOURCES}
    ${IMGUI_SOURCES}
)

# Main executable
add_executable(${PROJECT_NAME}
    fortnite-dma-raw/main.cpp
)

# Link core library to executable
target_link_libraries(${PROJECT_NAME} fortnite_dma_core)

# Platform-specific libraries
if(WIN32)
    target_link_libraries(${PROJECT_NAME}
        setupapi
        advapi32
        user32
        gdi32
        ole32
        oleaut32
        ws2_32
        winspool
        shell32
        winmm
        version
        imm32
        opengl32
    )
    
    # Add VMMDLL library if available
    if(USE_VMMDLL_BACKEND)
        find_library(VMMDLL_LIB
            NAMES vmm vmmdll
            PATHS ${CMAKE_CURRENT_SOURCE_DIR}/fortnite-dma-raw/dependencies/memprocfs
            PATH_SUFFIXES lib lib64
        )
        
        if(VMMDLL_LIB)
            target_link_libraries(${PROJECT_NAME} ${VMMDLL_LIB})
            add_definitions(-DUSE_VMMDLL_BACKEND)
            message(STATUS "Found VMMDLL library: ${VMMDLL_LIB}")
        else()
            message(WARNING "VMMDLL library not found")
        endif()
    endif()
    
elseif(UNIX)
    target_link_libraries(${PROJECT_NAME}
        pthread
        dl
        m
    )
    
    # Add memflow libraries if available
    if(USE_MEMFLOW_BACKEND AND MEMFLOW_FOUND)
        target_link_libraries(${PROJECT_NAME} ${MEMFLOW_LIBRARIES})
    endif()
endif()

# Compiler-specific options
if(MSVC)
    target_compile_options(fortnite_dma_core PRIVATE 
        /W4 /WX- /permissive- /Zc:__cplusplus
    )
    target_compile_options(${PROJECT_NAME} PRIVATE 
        /W4 /WX- /permissive- /Zc:__cplusplus
    )
    
    # Optimization flags
    if(CMAKE_BUILD_TYPE STREQUAL "Release")
        target_compile_options(fortnite_dma_core PRIVATE /O2 /GL)
        target_compile_options(${PROJECT_NAME} PRIVATE /O2 /GL)
        target_link_options(${PROJECT_NAME} PRIVATE /LTCG)
    endif()
    
else()
    target_compile_options(fortnite_dma_core PRIVATE 
        -Wall -Wextra -Wpedantic -Wno-unused-parameter
    )
    target_compile_options(${PROJECT_NAME} PRIVATE 
        -Wall -Wextra -Wpedantic -Wno-unused-parameter
    )
    
    # Optimization flags
    if(CMAKE_BUILD_TYPE STREQUAL "Release")
        target_compile_options(fortnite_dma_core PRIVATE -O3 -flto)
        target_compile_options(${PROJECT_NAME} PRIVATE -O3 -flto)
        target_link_options(${PROJECT_NAME} PRIVATE -flto)
    endif()
endif()

# Debug configuration
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    add_definitions(-D_DEBUG -DDEBUG_LOGGING)
    if(ENABLE_COPILOT_FEATURES)
        add_definitions(-DENABLE_COPILOT_FEATURES)
    endif()
endif()

# Testing
if(BUILD_TESTS)
    enable_testing()
    find_package(GTest)
    
    if(GTest_FOUND)
        file(GLOB_RECURSE TEST_SOURCES "tests/*.cpp")
        
        add_executable(${PROJECT_NAME}_tests ${TEST_SOURCES})
        target_link_libraries(${PROJECT_NAME}_tests 
            fortnite_dma_core
            GTest::GTest 
            GTest::Main
        )
        
        add_test(NAME ${PROJECT_NAME}_tests COMMAND ${PROJECT_NAME}_tests)
        message(STATUS "Tests enabled")
    else()
        message(WARNING "Google Test not found, disabling tests")
    endif()
endif()

# Installation
install(TARGETS ${PROJECT_NAME}
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
)

install(FILES 
    README.md
    PROXMOX_SETUP_GUIDE.md
    MEMFLOW_INTEGRATION.md
    .github_copilot_instructions.md
    DESTINATION share/doc/${PROJECT_NAME}
)

# Package configuration
set(CPACK_PACKAGE_NAME ${PROJECT_NAME})
set(CPACK_PACKAGE_VERSION ${PROJECT_VERSION})
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Fortnite DMA with Memflow Backend Support")
set(CPACK_PACKAGE_VENDOR "Community")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/LICENSE")
set(CPACK_RESOURCE_FILE_README "${CMAKE_CURRENT_SOURCE_DIR}/README.md")

if(WIN32)
    set(CPACK_GENERATOR "ZIP;NSIS")
else()
    set(CPACK_GENERATOR "TGZ;DEB")
endif()

include(CPack)

# Status report
message(STATUS "=== Build Configuration ===")
message(STATUS "Platform: ${PLATFORM_NAME}")
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "C++ standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "Memflow backend: ${USE_MEMFLOW_BACKEND}")
message(STATUS "VMMDLL backend: ${USE_VMMDLL_BACKEND}")
message(STATUS "Tests: ${BUILD_TESTS}")
message(STATUS "Copilot features: ${ENABLE_COPILOT_FEATURES}")
message(STATUS "=============================")