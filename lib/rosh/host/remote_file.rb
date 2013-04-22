require 'erb'
require 'ostruct'
require 'tempfile'

require_relative 'remote_file_system_object'


class Rosh
  class Host
    class RemoteFile < RemoteFileSystemObject
      def initialize(path, remote_shell)
        super(path, remote_shell)

        @unwritten_contents = nil
      end

      # @return [String] The contents of the remote file.
      def contents
        @remote_shell.cat(@path)
      end

      # Stores +new_contents+ in memory until #save is called.
      #
      # @param [String] new_contents Contents to write to the file on #save.
      def contents=(new_contents)
        @unwritten_contents = new_contents
      end

      # Sets the in-memory file contents to that of the template file, rendered
      # with values provided in +template_values+.
      #
      # @param [String] template_file Path to the file to use as a template.
      # @param [Hash] template_values Values to pass in to the template.
      # @return [String] Contents for the file.
      def from_template(template_file, **template_values)
        namespace = OpenStruct.new(template_values)
        template = ERB.new(File.read(template_file))
        @unwritten_contents = template.result(namespace.instance_eval { binding })

        @unwritten_contents
      end

      # If in-memory contents exist, writes them to the file.
      #
      # @return [Boolean] +true+ if successful; +false+ if not.
      def save
        if @unwritten_contents
          tempfile = Tempfile.new('rosh_remote_file')
          tempfile.write(@unwritten_contents)
          tempfile.rewind
          @remote_shell.upload(tempfile, @path)

          tempfile.unlink
          @unwritten_contents = nil

          @remote_shell.last_exit_status.zero?
        else
          false
        end
      end
    end
  end
end
