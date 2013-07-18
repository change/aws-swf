# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "aws-swf"
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Vijay Krishna Ramesh"]
  s.date = "2013-07-18"
  s.email = "vijay@change.org"
  s.executables = ["swf_run"]
  s.extra_rdoc_files = ["README.md"]
  s.files = ["Gemfile", "Gemfile.lock", "LICENSE", "README.md", "bin/swf_run", "spec/swf/activity_task_handler_spec.rb", "spec/swf/boot_spec.rb", "spec/swf/decision_task_handler_spec.rb", "spec/swf/runner_spec.rb", "spec/swf/task_handler_spec.rb", "spec/swf_spec.rb", "lib/swf/activity_task_handler.rb", "lib/swf/boot.rb", "lib/swf/decision_task_handler.rb", "lib/swf/runner.rb", "lib/swf/task_handler.rb", "lib/swf.rb", "lib/workflows.rb"]
  s.homepage = "http://yoursite.example.com"
  s.rdoc_options = ["--main", "README.md"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.23"
  s.summary = "What this thing does"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 0"])
    else
      s.add_dependency(%q<rspec>, [">= 0"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 0"])
  end
end
