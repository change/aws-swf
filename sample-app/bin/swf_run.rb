#!/usr/bin/env ruby

require './lib/boot'

def run!
  startup_hash = ARGV.inject(Hash.new(0)) {|h,i| h[i.to_sym] += 1; h }
  SampleApp::Boot.startup(startup_hash[:d], startup_hash[:w], true)
end

run!
