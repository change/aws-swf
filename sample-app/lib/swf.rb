require 'aws-swf'

module SampleApp; end
module SampleApp::Workflows; end
module SampleApp::Activities; end

require './lib/aws_helper'
require './lib/workflows/helpers'
require './lib/activities/helpers'

Dir.glob(File.dirname(__FILE__) + '/workflows/*', &method(:require))
Dir.glob(File.dirname(__FILE__) + '/activities/*', &method(:require))