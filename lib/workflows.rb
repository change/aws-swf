require 'swf'

module SWF
  module Workflows
    extend self

    def effect_workflow_type(name, version, options={})
      @workflow_types ||= {}
      @workflow_types[[name, version]] ||= SWF.domain.workflow_types.find {|t| [t.name, t.version] == [name, version] }
      @workflow_types[[name, version]] ||= SWF.domain.workflow_types.create(name, version, options)
    end

    def start(options, execution_options)
      execution_options[:task_list] ||= SWF.task_list
      execution_options.merge!({
        input: options.to_json
      })
      workflow_type.start_execution(execution_options)
    end

    def wait_for_workflow_execution_complete(workflow_execution)
      sleep 1 while :open == (status = workflow_execution.status)
      raise "workflow_execution #{workflow_execution} did not succeed: #{workflow_execution.status}" unless status == :completed
    end

  end
end
