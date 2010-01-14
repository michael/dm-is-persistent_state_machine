require 'spec_helper'

describe DataMapper::Is::PersistentStateMachine do
  
  before(:all) do
    DataMapper.auto_migrate!
    
    # add some states
    open = ProjectState.create(:name => "Open", :code => "open")
    reviewed = ProjectState.create(:name => "Reviewed", :code => "reviewed")
    confirmed = ProjectState.create(:name => "Confirmed", :code => "confirmed")
    
    # add some events
    review_evt = ProjectStateEvent.create(:code => "review", :name => "Review")
    confirm_evt = ProjectStateEvent.create(:code => "confirm", :name => "Confirm")
    
    # add some transitions    
    open_reviewed = StateTransition.create(:state => open, :target => reviewed, :state_event => review_evt)
    reviewed_confirmed = StateTransition.create(:state => reviewed, :target => confirmed, :state_event => confirm_evt)
  end
  
  describe "with active DM Identity Map" do
    
    before :each do
      Project.auto_migrate!
      StateChange.auto_migrate!
    end
    
    it "should log state changes" do
      @project = Project.create(:name => "Operation X", :state => ProjectState.first(:code => "open"))
      @project.state.code.should == "open"
      @project.trigger_event!('review')
      Project.first(:name => "Operation X").state.code.should == "open" # not persistent yet
      
      StateChange.count.should == 0
      @project.state.code.should == "reviewed"
      @project.save
      StateChange.count.should == 1
    end   
  end
end