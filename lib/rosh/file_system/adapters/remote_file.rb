require 'erb'
require 'ostruct'
require 'tempfile'

require_relative 'remote_base'


class Rosh
  class FileSystem
    module Adapters

      # Object representing a file on a remote file system.
      class RemoteFile
        include RemoteBase

        class << self
          # @return [String] The contents of the remote file.
          def read(length=nil, offset=nil)
            return @unwritten_contents if @unwritten_contents

            cmd = "dd bs=1 if=#{@path}"
            cmd << " count=#{length}" if length
            cmd << " skip=#{offset}" if offset
            results = current_shell.exec(cmd)
            contents = results.split /[^\n]+records in\r?\n/

            current_shell.last_exit_status.zero? ? contents.first : nil
          end

          def readlines(separator)
            contents = self.read
            contents.lines(separator)
          end

          def copy(destination)
            current_shell.cp(@path, destination)
          end

          # Stores +new_contents+ in memory until #save is called.
          #
          # @param [String] new_contents Contents to write to the file on #save.
          def write(new_contents)
            @unwritten_contents = new_contents

            true
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

          private

          # Writes all in-memory contents to a local Tempfile, then uploads the
          # Tempfile to the remote path.  Notifies observers about the new contents.
          #
          # @return [Boolean] +true+ if creating was successful; +false+ if not.
          def upload_new_content
            tempfile = Tempfile.new('rosh_remote_file')
            tempfile.write(@unwritten_contents)
            tempfile.rewind
            current_shell.upload(tempfile, @path)

            tempfile.unlink
            @unwritten_contents = nil

            current_shell.last_exit_status.zero?
          end
        end

        #-----------------------------------------
        # TODO: This method needs to get used!
        #-----------------------------------------

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

          @unwritten_contents = new_contents
        end
      end
    end
  end
end
