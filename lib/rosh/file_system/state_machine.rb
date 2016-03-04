require 'simple_states'
require_relative '../logger'
require_relative '../event'

class Rosh
  class FileSystem
    module StateMachine
      def self.included(base)
        base.send :include, SimpleStates
        base.states :transient, :persisted, :dirtied

        base.event :update,
          to: :dirtied,
          unless: %i[transient? old_equal_to_new failed_command?],
          after: :log_uncommitted_event

        base.event :persist,
          to: :persisted,
          unless: [:failed_command?],
          after: :notify_observers

        base.event :delete,
          to: :transient,
          unless: [:failed_command?],
          after: :notify_observers

        base.send :include, Rosh::Logger
      end

      attr_accessor :state, :dirtied_at, :persisted_at, :transient_at

      def failed_command?(_event, _attrib, cmd_result, _as_sudo, _changed)
        result = !cmd_result.exit_status.zero?
        log "State Machine: failed_command? #{result}"

        result
      end

      def old_equal_to_new(_event, _attrib, _cmd_result, _as_sudo, changed)
        result = changed[:from] == changed[:to]
        log "State Machine: old_equal_to_new #{result}"

        result
      end

      def object_topic
        @object_topic ||= self.class.name.declassify + 's'
      end

      def log_uncommitted_event(*args)
        log "State Machine: Uncommitted event: #{self}, #{args}"
        @uncommitted_events ||= []

        #         @uncommitted_events << {
        #           object: self,
        #           attribute: args[1],
        #           result: args[2],
        #           as_sudo: args[3],
        #           from: args[4][:from],
        #           to: args[4][:to]
        #         }
        @uncommitted_events << Rosh::Event.new(*args)
      end

      def notify_observers(*args)
        log "State Machine: Notifying on topic '#{object_topic}'"

        if @uncommitted_events.nil?
          log "State Machine: No uncommitted events to publish. Args: #{args}"
        else
          @uncommitted_events.each do |event|
            publish(object_topic, event)
          end
        end

        publish(object_topic, Rosh::Event.new(*args))
      end
    rescue ArgumentError
      puts "arg1: #{event}"
      raise
    end
  end
end
