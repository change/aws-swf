require 'aws-sdk'

module SWF

  class UnknownSWFDomain < StandardError; end
  class UndefinedDomainName < StandardError; end
  class UndefinedTaskList < StandardError; end

  extend self

  def swf
    @swf ||= AWS::SimpleWorkflow.new
  end

  def domain_name
    raise UndefinedDomainName, "domain name not defined" unless @domain_name
    @domain_name
  end

  # in the runner context, where domain_name comes from ENV settings we call
  # SWF.domain_name = MyApp::Settings.swf_domain
  def domain_name=(d)
    @domain_name = d
  end

  SLOT_TIME = 1

  def domain_exists?(d)
    collision = 0
    begin
      swf.domains[d].exists?
    rescue => e
      collision += 1 if collision < 10
      max_slot_delay = 2**collision - 1
      sleep(SLOT_TIME * rand(0 .. max_slot_delay))
      retry
    end
  end

  def domain
    # if we need a new domain, make it in the aws console
    raise UnknownSWFDomain, "#{domain_name} is not a valid SWF domain" unless domain_exists?(domain_name)
    swf.domains[domain_name]
  end

  def task_list=(tl)
    @task_list = tl
  end

  def task_list
    @task_list or raise UndefinedTaskList, "task_list must be defined via SWF.task_list = <task_list>"
  end

end
