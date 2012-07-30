# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'simple-client/version'

Gem::Specification.new do |s|
  s.name = "simple-client"
  s.version = SimpleClient::VERSION

  s.authors = ["matt robbins"]
  s.email = ["mcrobbins@gmail.com"]
  s.description = "simple wrapper for Net:HTTP"

  s.files = Dir.glob("{features,lib,bin,test,config,vendor,.bundle}/**/*") +  %w(Gemfile Gemfile.lock)

  s.require_paths = ["lib"]
  s.rubygems_version = "1.3.6"
  s.summary = "simple wrapper for Net:HTTP"

end
