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

  property :id,             Serial
  property :code,           String, :required => true, :unique => true, :unique_index => true
  property :name,           String, :required => true, :unique => true, :unique_index => true
  property :editable,       Boolean, :default => true
  property :sorter,         Integer
  property :type,           Discriminator

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
  
  property :id,   Serial
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
        DataMapper.logger.info "registering persistent state machine..."
        
        # Add class-methods
        extend DataMapper::Is::PersistentStateMachine::ClassMethods
        extend Forwardable
        # Add instance-methods
        include DataMapper::Is::PersistentStateMachine::InstanceMethods
        
        target_model_name = self.name.snake_case
        
        # target object must have a status associated
        property :state_id, Integer, :required => true, :min => 1
        belongs_to :state
        
        has n, Extlib::Inflection.pluralize(target_model_name+"StateChange").to_sym
        
        # generate a FooState class that is derived from State        
        state_model = Object.full_const_set(self.to_s+"State", Class.new(State))
        # generate a FooStateEvent class that is derived from StateEvent
        event_model = Object.full_const_set(self.to_s+"StateEvent", Class.new(StateEvent))

        state_change_model = Class.new do
          include DataMapper::Resource

          property :id, ::DataMapper::Types::Serial

          property :from_id, Integer,   :required => true, :min => 1
          property :to_id, Integer,     :required => true, :min => 1
          property :user_id, Integer
          property Extlib::Inflection.foreign_key(target_model_name).to_sym, Integer, :required => true, :min => 1
          property :created_at, DateTime

          # associations
          belongs_to :user
          belongs_to :from, "State"
          belongs_to :to,   "State"
          belongs_to target_model_name.to_sym
        end
        
        state_change_model = Object.full_const_set(self.to_s+"StateChange",state_change_model)
        
        self_cached = self
        
        after :save do
          if (@prev_state && @prev_state != state)
            @state_change = state_change_model.create(:from => @prev_state, :to => state, :created_at => DateTime.now, :user => @user, Extlib::Inflection.foreign_key(target_model_name).to_sym => self.id)
            @prev_state = nil # clean up cache
            @user = nil
          end
        end

        # define delegators
        def_delegators :@state, :events        
      end
      
      ##
      # fired after trigger_event! is called on resource
      #
      module ClassMethods
        
      end # ClassMethods
 
      module InstanceMethods
        def trigger_event!(event_code, user)
          # cache prev_state and the user that is triggering the event
          @prev_state = self.state
          @user = user

          # delegate to State#trigger!
          self.state.trigger_event!(self, event_code)
        end
        
        # hookable
        def after_trigger_event(event)

        end
      end # InstanceMethods
    end # PersistentStateMachine
  end # Is
end # DataMapper