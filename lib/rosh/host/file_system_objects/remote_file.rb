require 'erb'
require 'ostruct'
require 'tempfile'

require_relative 'remote_base'


class Rosh
  class Host
    module FileSystemObjects

      # Object representing a file on a remote file system.
      class RemoteFile < RemoteBase

        # @param [String] path
        # @param [String,Symbol] host_label
        def initialize(path, host_label)
          super(path, host_label)

          @unwritten_contents = nil
        end

        # @return [String] The contents of the remote file.
        def contents
          return @unwritten_contents if @unwritten_contents

          results = current_shell.cat(@path)

          current_shell.last_exit_status.zero? ? results : nil
        end

        # Stores +new_contents+ in memory until #save is called.
        #
        # @param [String] new_contents Contents to write to the file on #save.
        def contents=(new_contents)
          if current_shell.check_state_first? && new_contents == contents
            #log 'SKIP: check_state_first is true and file contents are identical.'
            return
          end

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
          new_contents = template.result(namespace.instance_eval { binding })

          if current_shell.check_state_first? && contents == new_contents
            #log 'SKIP: check_state_first is true and file contents are identical to the rendered template.'
            return
          end

          @unwritten_contents = new_contents
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
          if current_shell.check_state_first? && exists?
            #log 'SKIP: check_state_first is true and file already exists.'
            return
          end

          current_shell.exec("touch #{@path}")

          success = current_shell.last_exit_status.zero?

          if success
            changed
            notify_observers(self,
              attribute: :path, old: nil, new: @path,
              as_sudo: current_shell.su?)
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
          current_shell.upload(tempfile, @path)

          tempfile.unlink
          success = current_shell.last_exit_status.zero?

          if success && old_contents != @unwritten_contents
            changed
            notify_observers(self,
              attribute: :contents, old: old_contents, new: @unwritten_contents,
              as_sudo: current_shell.su?)
          end

          @unwritten_contents = nil

          success
        end
      end
    end
  end
end
