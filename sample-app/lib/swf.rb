require './lib/aws_helper'

# until SWF is gemified, do this one relative_require
# it will add swf to our $: path
require_relative '../../lib/swf'

require 'workflows'
require 'swf/boot'
require 'swf/decision_task_handler'
require 'swf/activity_task_handler'

module SampleApp; end
module SampleApp::Workflows; end
module SampleApp::Activities; end

require './lib/workflows/helpers'
require './lib/activities/helpers'

Dir.glob(File.dirname(__FILE__) + '/workflows/*', &method(:require))
Dir.glob(File.dirname(__FILE__) + '/activities/*', &method(:require))