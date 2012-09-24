require './lib/swf/runner'

describe SWF::Runner do
  before do
    SWF.stub(:domain_name) { 'phony_domain' }
    SWF.stub(:domain) { double(:domain, name: SWF.domain_name ) }
  end

  subject { SWF::Runner.new('phony_domain', 'phony_task_list') }

  it "has a handle on the domain" do
    subject.domain.name.should == 'phony_domain'
  end

  describe "#be_decider" do
    it "polls for decision tasks" do
      subject.stub(:domain) { double(:domain,
        decision_tasks: double(:decision_tasks).tap {|o|
          o.should_receive(:poll).with('phony_task_list') {|&blk|
            task = :placeholder_decision_task
            SWF::DecisionTaskHandler.should_receive(:handle).with(subject, task)
            blk.call task
          }
        }
      ) }

      subject.be_decider
    end
  end

  describe "#be_worker" do
    it "polls for activity tasks" do
      subject.stub(:domain) { double(:domain,
        activity_tasks: double(:activity_tasks).tap {|o|
          o.should_receive(:poll).with('phony_task_list') {|&blk|
            task = :placeholder_activity_task
            SWF::ActivityTaskHandler.should_receive(:handle).with(subject, task)
            blk.call task
          }
        }
      ) }

      subject.be_worker
    end
  end

end
