require 'rubygems'
require 'forwardable'

require 'dm-core'
require 'dm-types'
require 'dm-timestamps'
require 'dm-validations'
require 'dm-aggregates'


# Temporary workaround until this is extracted into a gem
$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))

require 'dm-is-persistent_state_machine/is/persistent_state_machine'

# Activate the plugin
DataMapper::Model.append_extensions DataMapper::Is::PersistentStateMachine