module Memento
  class Session < ActiveRecord::Base
    self.table_name = "memento_sessions"

    has_many :states, -> { order "id DESC" },
             :class_name => "Memento::State", :dependent => :delete_all

    # attr_accessible nil

    validates_presence_of :user_id

    def add_state(action_type, record)
      states.store(action_type, record)
    end

    def undo
      states.map(&:undo).inject(Memento::ResultArray.new) do |results, result|
        result.state.destroy if result.success?
        results << result
      end
    ensure
      destroy if states.count.zero?
    end

    def undo!
      transaction do
        undo.tap do |results|
          raise Memento::ErrorOnRewind if results.failed?
        end
      end
    end
  end
end