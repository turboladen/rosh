class Rosh
  class ProcessManager
    class RemoteProcTable < Struct.new(:user, :pid, :cpu, :mem, :vsz, :rss, :tty,
      :stat, :start, :time, :command)

      # @!attribute [r] user
      #   @return [String] The username of the process owner.

      # @!attribute [r] pid
      #   @return [Integer] The process ID of the process.

      # @!attribute [r] cpu
      #   @return [Float] CPU utilization of the process.

      # @!attribute [r] mem
      #   @return [Float] Physical memory utilization of the process.

      # @!attribute [r] vsz
      #   @return [Integer] Virtual memory size of the process in KB.

      # @!attribute [r] rss
      #   @return [Float] Resident set size; the non-swapped physical memory that
      #     the process has used in KB.

      # @!attribute [r] tty
      #   @return [String] TTY controlling the process.

      # @!attribute [r] stat
      #   @return [String] State of the process.

      # @!attribute [r] start
      #   @return [Time] Time the process was started.

      # @!attribute [r] time
      #   @return [String] Cumulative CPU time.

      # @!attribute [r] command
      #   @return [String] The command with all of its arguments.
    end
  end
end
