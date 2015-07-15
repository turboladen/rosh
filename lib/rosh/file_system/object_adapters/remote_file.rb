require 'erb'
require 'ostruct'
require 'tempfile'

require_relative 'remote_base'
require_relative 'remote_stat_methods'

class Rosh
  class FileSystem
    module ObjectAdapters
      # Object representing a file on a remote file system.
      module RemoteFile
        include RemoteBase
        include RemoteStatMethods

        attr_accessor :unwritten_contents

        # @todo Do something with the block.
        # @return [Boolean]
        def create(&_block)
          host.shell.exec_internal "touch #{@path}"
          result = host.shell.last_exit_status.zero?
          exit_status = result ? 0 : 1

          private_result(result, exit_status)
        end

        # @return [String] The contents of the remote file.
        def read(length = nil, offset = nil)
          private_result(@unwritten_contents, 0) if @unwritten_contents

          cmd = "dd bs=1 if=#{@path}"
          cmd << " count=#{length}" if length
          cmd << " skip=#{offset}" if offset
          results = host.shell.exec_internal(cmd).string

          if results.match /.*No such file.*/m
            bad_info results
            ex = Rosh::ErrorENOENT.new(@path)
            return private_result(ex, 1)
          end

          output = results.split /[^\n]+records in\r?\n/

          contents = if host.shell.last_exit_status.zero?
                       output.first
                     else
                       ''
          end

          private_result(contents, 0)
        end

        def readlines(separator)
          contents = read

          private_result contents.lines(separator), 0
        end

        def copy(destination)
          cmd = "cp #{@path} #{destination}"
          result = host.shell.exec_internal(cmd)

          if host.shell.last_exit_status.zero? && result.nil?
            private_result(true, 0)
          end

          ex = if result.match /No such file or directory/
                 bad_info result
                 Rosh::ErrorENOENT.new(@path)
               elsif result.match /omitting directory/
                 Rosh::ErrorEISDIR.new(@path)
          end

          private_result(ex, 1)
        end

        # If in-memory contents exist, writes them to the file.
        #
        # @return [Boolean] +true+ if successful or no change; +false+ if not
        #   successful.
        def save
          create_ok = exists? ? true : create
          upload_ok = @unwritten_contents ? upload_new_content : true

          result = create_ok && upload_ok
          exit_status = result ? 0 : 1

          private_result(result, exit_status)
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
          host.shell.upload(tempfile, @path)

          tempfile.unlink
          @unwritten_contents = nil

          host.shell.last_exit_status.zero?
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
