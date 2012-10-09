#!/usr/bin/env ruby
require 'json'
require 'swf/runner'

module SWF; end

module SWF::Boot

  class StartupFailure < StandardError; end

  extend self

  def startup(deciders, workers, wait_for_children = false)
    # may need to use Process.spawn to deal with file descripter being stale mumbo jumbo

    child_pids =  deciders.to_i.times.map {
      Process.fork {
        Process.daemon(true) unless wait_for_children
        rescued = false
        begin
          swf_runner.be_decider
        rescue => e
          error = {
            error: e.to_s,
            backtrace: e.backtrace.join("\n")
          }
          if rescued
            raise SWF::Boot::StartupFailure, JSON.pretty_unparse(error)
          else
            rescued = true
            retry
          end
        end
      }
    }

    child_pids += workers.to_i.times.map {
      Process.fork {
        Process.daemon(true) unless wait_for_children
        rescued = false
        begin
          swf_runner.be_worker
        rescue => e
          error_json = {
            error: e.to_s,
            backtrace: e.backtrace.join("\n")
          }

          # log the error to s3
          `echo '#{JSON.pretty_unparse(error_json)}' | ruby /data/machine-learning/feature-matrix/ec2/s3_logger.rb workers`

          unless rescued
            rescued = true
            retry
          end

        end
      }
    }

    puts "Forked #{deciders} deciders and #{workers} workers..."

    if wait_for_children
      %w(TERM INT).each {|signal| Signal.trap(signal) { terminate_children(child_pids) } }
      puts "Waiting on them..."
      child_pids.each {|pid| Process.wait(pid) }
    else
      child_pids.each {|pid| Process.detach(pid) }
    end
  end

  def terminate_children(child_pids)
    child_pids.each {|pid|
      puts "Terminating #{pid}"
      Process.kill("TERM", pid)
    }
  end

  def swf_runner
    # define this in your usage
    SWF::Runner.new(settings[:domain_name], settings[:task_list_name])
  end

  def settings
    {domain_name: 'domain', task_list_name: 'task_list_name'}
  end

end
