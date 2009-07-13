class Memento::State < ActiveRecord::Base
  set_table_name "memento_states"
  
  belongs_to :session, :class_name => "Memento::Session"
  belongs_to :record, :polymorphic => true
  
  validates_presence_of :session
  validates_presence_of :record
  validates_presence_of :action_type
  validates_inclusion_of :action_type, :in => Memento::Action::Base.action_types, :allow_blank => true
  
  before_create :set_record_data
  
  def self.store(action_type, record)
    self.new(:action_type => action_type.to_s, :record => record) do |state|
      state.save if state.fetch?
    end
  end
  
  def undo
    Memento::Result.new(action.undo, self)
  end
  
  def record_data
    @record_data ||= Marshal.load(super)
  end
  
  def record_data=(data)
    @record_data = nil
    super(Marshal.dump(data))
  end
  
  def fetch?
    action.fetch?
  end
  
  def new_object
    object = record_type.constantize.new
    yield(object) if block_given?
    object
  end
  
  def rebuild_object(*skip)
    skip = skip ? skip.map(&:to_sym) : []
    new_object do |object|
      record_data.each do |attribute, value|
        object.send(:"#{attribute}=", value) unless skip.include?(attribute.to_sym)
      end
      yield(object) if block_given?
    end
  end
  
  private
  
  def set_record_data
    self.record_data = action.fetch
  end
  
  def action
    "memento/action/#{action_type}".classify.constantize.new(self)
  end
  
end