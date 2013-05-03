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
        @shell.cat(@path)
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
      # @return [Boolean] +true+ if successful or no change; +false+ if not
      #   successful.
      def save
        create_ok = exists? ? true : create
        upload_ok = @unwritten_contents ? upload_new_content : true

        create_ok && upload_ok
      end

      #-------------------------------------------------------------------------
      # Privates
      #-------------------------------------------------------------------------
      private

      # Just creates the file; no content added.  Notifies observers with the
      # new path.
      #
      # @return [Boolean] +true+ if creating was successful; +false+ if not.
      def create
        @shell.exec("touch #{@path}")

        success = @shell.last_exit_status.zero?

        if success
          changed
          notify_observers(self, attribute: :path, old: nil, new: @path)
        end

        success
      end

      # Writes all in-memory contents to a local Tempfile, then uploads the
      # Tempfile to the remote path.  Notifies observers about the new contents.
      #
      # @return [Boolean] +true+ if creating was successful; +false+ if not.
      def upload_new_content
        old_contents = contents

        tempfile = Tempfile.new('rosh_remote_file')
        tempfile.write(@unwritten_contents)
        tempfile.rewind
        @shell.upload(tempfile, @path)

        tempfile.unlink
        success = @shell.last_exit_status.zero?

        if success && old_contents != @unwritten_contents
          changed
          notify_observers(self, attribute: :contents, old: old_contents,
            new: @unwritten_contents)
        end

        @unwritten_contents = nil

        success
      end
    end
  end
end
