//
//  File.swift
//  swift-composable-architecture
//
//  Created by Marco Vazquez on 12/10/22.
//

Pod::Spec.new do |s|
s.name             = 'ComposableArchitecture'
s.version          = '0.1.0'
s.summary          = 'Composable Architecture pod'

s.homepage         = "https://github.com/marco-evc/swift-composable-architecture"
s.license          = { :type => 'MIT', :file => 'LICENSE.md' }
s.author           = { 'Pointfree' => "https://www.pointfree.co/" }
s.source           = { :git => "https://github.com/marco-evc/swift-composable-architecture.git", :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'

  s.source_files = 'Sources/BloggerBird/**/*'
  end
