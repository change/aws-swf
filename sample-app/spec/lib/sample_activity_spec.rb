require './lib/sample_activity'

describe SampleActivity do
  let(:test_run_identifier) { "spec-aws-swf/%08x-%08x" % [Time.now.to_i, rand(0xFFFFFFFF)] }
  let(:settings) {
    {
      swf_domain:     'aws-swf-test',
      s3_bucket:      'aws-swf-test',
      s3_path:        test_run_identifier,
      local_data_dir: '/tmp'
    }
  }
  let(:runner){
    double(:runner,
      settings: settings
    )
  }

  let(:task_list){ 'lorem_task_list' }


  describe SampleActivity::ActivityTaskHandler do


    let(:activity_type){ double(:activity_type, name: 'sample_activity', version: '1') }

    let(:activity_input) {
      {
        "input_param" => "input",
        "other_param" => "foobar"
      }
    }
    let(:activity_task) {
      double(:task,
        activity_type: activity_type,
        input: activity_input.to_json,
        local_data_dir: '/tmp'
      )
    }

    let(:handler) { SampleActivity::ActivityTaskHandler.new(runner, activity_task) }


    let(:input){ JSON.parse(activity_task.input) }
    describe '#handle_sample_activity' do
      it "returns the params" do
        handler.send(:handle_sample_activity).should == activity_input.to_json
      end
    end
  end
end
