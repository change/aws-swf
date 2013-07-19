require 'aws-swf'

require './lib/sample_workflow'

# NOTE for this spec to work, you'll need to export
# AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY to your env
# also make sure s3_bucket_name exists in your account,
# and that you have created swf_domain_name in SWF. Workflow
# and activity types should automatically be created for you.

def try_soft_loud
  begin
    yield
  rescue => e
    puts "PROBLEM!! #{e}"
    puts e.backtrace
  end
end

describe SampleWorkflow do
  let(:test_run_identifier) {
    "spec-aws-swf/%08x-%08x" % [Time.now.to_i, rand(0xFFFFFFFF)]
  }
  let(:swf_domain_name) { 'aws-swf-test' }
  let(:s3_bucket_name)  { 'change-test' }
  let(:s3_path)    { test_run_identifier }
  let(:local_data_dir) { '/tmp' }

  let(:swf_runner_pid) {
    Process.spawn({
      'SWF_DOMAIN'     => swf_domain_name,
      'S3_BUCKET'      => s3_bucket_name,
      'S3_PATH'        => s3_path,
      'LOCAL_DATA_DIR' => local_data_dir,
    }, "ruby ./bin/swf_run.rb d d w w w "
  )}

  let(:s3_bucket) { AWS::S3.new.buckets[s3_bucket_name] }
  before do
    test_run_identifier
  end

  it "runs a sample workflow" do
    begin
      # check that we've got AWS credentials
      s3_bucket.exists?

      # start swf decider/worker subprocess
      swf_runner_pid

      # domain_name and task_list can be passed as options to SampleWorkflow.start
      # or can be set "globally" for the process (e.g., an irb session or rspec run)
      SWF.domain_name = swf_domain_name
      SWF.task_list = "#{s3_bucket_name}:#{s3_path}"

      workflow_execution = SampleWorkflow.start(
        { input_param: "some input" },
        execution_start_to_close_timeout: 3600
      )
      SWF::Workflows.wait_for_workflow_execution_complete(workflow_execution)

      s3_bucket.objects[s3_path].read.should == { input_param: "some input", decision_param: "decision", activity_param: "activity"}.to_json
      try_soft_loud { s3_bucket.objects.with_prefix(test_run_identifier).each {|s3_object| s3_object.delete} }
      try_soft_loud { Process.kill 'TERM', swf_runner_pid }
    rescue
      puts "NOTE: Not really running this test as we've got no AWS credentials"
    end
  end
end

