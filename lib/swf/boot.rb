#!/usr/bin/env ruby
require 'json'
require 'swf/runner'

module SWF; end

module SWF::Boot

  class DeciderStartupFailure < StandardError; end
  class WorkerStartupFailure < StandardError; end

  extend self

  def startup(deciders, workers, wait_for_children = false, &at_rescue)
    child_pids =  deciders.to_i.times.map {
      Process.fork {
        Process.daemon(true) unless wait_for_children
        rescued = false
        begin
          swf_runner.be_decider
        rescue => e
          error = {
            error: e.inspect,
            backtrace: e.backtrace
          }
          if rescued
            begin
              raise SWF::Boot::DeciderStartupFailure, JSON.pretty_unparse(error)
            rescue SWF::Boot::DeciderStartupFailure => rescued_e
              if at_rescue
                at_rescue.call(rescued_e.to_s)
              else
                raise rescued_e
              end
            end
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
          error = {
            error: e.inspect,
            backtrace: e.backtrace
          }
          if rescued
            begin
              raise SWF::Boot::WorkerStartupFailure, JSON.pretty_unparse(error)
            rescue SWF::Boot::WorkerStartupFailure => rescued_e
              if at_rescue
                at_rescue.call(rescued_e.to_s)
              else
                raise rescued_e
              end
            end
          else
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

    child_pids

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
