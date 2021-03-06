# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "aws-swf"
  s.version = "0.1.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Vijay Krishna Ramesh", "Tim James"]
  s.date = "2013-08-07"
  s.email = ["vijay@change.org"]
  s.executables = ["swf_run"]
  s.extra_rdoc_files = ["README.md"]
  s.files = ["Gemfile", "Gemfile.lock", "LICENSE", "README.md", "bin/swf_run", "spec/swf/activity_task_handler_spec.rb", "spec/swf/boot_spec.rb", "spec/swf/decision_task_handler_spec.rb", "spec/swf/runner_spec.rb", "spec/swf/task_handler_spec.rb", "spec/swf_spec.rb", "lib/aws-swf.rb", "lib/swf/activity_task_handler.rb", "lib/swf/boot.rb", "lib/swf/decision_task_handler.rb", "lib/swf/runner.rb", "lib/swf/task_handler.rb", "lib/swf/swf.rb", "lib/swf/workflows.rb"]
  s.homepage = "http://change.github.io/aws-swf"
  s.rdoc_options = ["--main", "README.md"]
  s.require_paths = ["lib", "lib/swf"]
  s.rubygems_version = "1.8.23"
  s.license = 'MIT'
  s.summary = "light framework for creating AWS Simple Workflow applications in Ruby."

  s.add_dependency "aws-sdk", "~> 1"
  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 2.1"])
    else
      s.add_dependency(%q<rspec>, [">= 2.1"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 2.1"])
  end
end
