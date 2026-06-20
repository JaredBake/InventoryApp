Pod::Spec.new do |s|
  s.name             = 'InventoryLib'
  s.version          = '1.0.0'
  s.summary          = 'C++ inventory business-logic library for the InventoryApp Flutter FFI bridge.'
  s.description      = <<-DESC
    Provides sorting, filtering, and custom-list rule-matching implemented in C++17.
    The Flutter layer calls into this code via dart:ffi using DynamicLibrary.process(),
    which requires the library to be statically linked into the app binary on iOS.
  DESC
  s.homepage         = 'https://github.com/JaredBake/InventoryApp'
  s.license          = { :type => 'MIT' }
  s.author           = { 'InventoryApp' => '' }
  s.source           = { :path => '.' }

  s.ios.deployment_target = '12.0'

  # Compile the C++ source and expose the public headers.
  # Paths are relative to this podspec (ios/), so ../cpp/ reaches the project root.
  s.source_files        = '../cpp/src/**/*.{cpp}', '../cpp/include/**/*.{h}'
  s.public_header_files = '../cpp/include/**/*.h'

  s.pod_target_xcconfig = {
    # Build with C++17 to match the top-level CMakeLists.txt.
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++17',
    'CLANG_CXX_LIBRARY'           => 'libc++',
    # Make the include/ directory available without a path prefix.
    'HEADER_SEARCH_PATHS'         => '"$(PODS_TARGET_SRCROOT)/../cpp/include"',
  }
end
