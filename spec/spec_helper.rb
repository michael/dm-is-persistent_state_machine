require 'rubygems'
 
require 'dm-core'
require 'dm-adjust'
require 'dm-aggregates'
require 'dm-types'
require 'dm-validations'
 
$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

require 'dm-is-persistent_state_machine'

DataMapper.setup(:default, 'sqlite3::memory:')
 
# classes/vars for tests

class Project
  include DataMapper::Resource
 
  property :id,       Serial
  property :name,     String
  
  is :persistent_state_machine
end
