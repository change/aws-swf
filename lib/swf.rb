# until we gemify SWF, do some path munging
$:.unshift(File.join(File.expand_path(File.dirname(__FILE__))))
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
  # FeatureMatrix::SWF.domain_name = FeatureMatrix::Settings.swf_domain
  def domain_name= d
    @domain_name = d
  end

  def domain
    # if we need a new domain, make it in the aws console
    raise UnknownSWFDomain, "#{domain_name} is not a valid SWF domain" unless swf.domains[domain_name].exists?
    swf.domains[domain_name]
  end

  def task_list= tl
    @task_list = tl
  end

  def task_list
    @task_list or raise UndefinedTaskList, "task_list must be defined via SWF.task_list = <task_list>"
  end

end
