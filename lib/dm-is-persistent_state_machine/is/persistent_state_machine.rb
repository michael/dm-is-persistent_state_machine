class StateTransition
  include DataMapper::Resource

  property :id,             Serial

  property :state_id,       Integer, :required => true, :min => 1
  property :target_id,      Integer, :required => true, :min => 1
  property :state_event_id, Integer, :required => true, :min => 1
  
  belongs_to :state
  belongs_to :target, 'State', :child_key => [:target_id]
  belongs_to :state_event
end

class State
  include DataMapper::Resource

  property :id,          Serial
  property :code,        String, :required => true, :unique => true, :unique_index => true
  property :name,        String, :required => true, :unique => true, :unique_index => true
  property :editable,    Boolean
  property :sorter,      Integer
  property :type,        Discriminator

  # outgoing transitions
  has n, :state_transitions, 'StateTransition', :child_key => [:state_id]
  
  def events
    evts = []
    state_transitions.each do |transition|
      # uses the generic event method
      evts << transition.state_event
    end
    evts
  end
  
  # obj is the caller object
  def trigger_event!(obj, event_code)
    event = StateEvent.first(:code => event_code)
    state_transitions.each do |transition|
      if transition.state_event == event    
        obj.state = transition.target
        obj.after_trigger_event(event)
        return true
      end
    end
    return false
  end
end

class StateEvent
  include DataMapper::Resource
  
  property :id, Serial
  property :code, String, :required => true, :unique => true, :unique_index => true
  property :name, String, :required => true, :unique => true, :unique_index => true
  property :type, Discriminator
end


module DataMapper
  module Is
    module PersistentStateMachine
      
      class DmIsPersistentStateMachineException < Exception; end
      
      ##
      # fired when plugin gets included into Resource
      #
      def self.included(base)
 
      end
 
      ##
      # Methods that should be included in DataMapper::Model.
      # Normally this should just be your generator, so that the namespace
      # does not get cluttered. ClassMethods and InstanceMethods gets added
      # in the specific resources when you fire is :example
      ##
    
      def is_persistent_state_machine
 
        # Add class-methods
        extend DataMapper::Is::PersistentStateMachine::ClassMethods
        extend Forwardable
        # Add instance-methods
        include DataMapper::Is::PersistentStateMachine::InstanceMethods
        
        # target object must have a status associated
        property :state_id, Integer, :required => true, :min => 1
        belongs_to :state
        
        DataMapper.logger.info "registering persistent state machine..."
        
        # define delegators
        def_delegators :@state, :events
        
        # generate a FooState class that is derived from State        
        state_model = Object.full_const_set(self.to_s+"State", Class.new(State))
        # generate a FooStateEvent class that is derived from StateEvent
        event_model = Object.full_const_set(self.to_s+"StateEvent", Class.new(StateEvent))
      end
      
      ##
      # fired after trigger_event! is called on resource
      #
      def after_trigger_event(event)
      end
  
      module ClassMethods
        
      end # ClassMethods
 
      module InstanceMethods
        def trigger_event!(event_code)
          # delegate to State#trigger!
          self.state.trigger_event!(self, event_code)
        end
      end # InstanceMethods
    end # PersistentStateMachine
  end # Is
end # DataMapper