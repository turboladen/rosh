require 'etc'


class Rosh
  class Host
    module FileSystemObjects
      class LocalBase
        File.singleton_methods.each do |meth|
          arg_methods = %i[
        identical? basename expand_path link open realdirpath realpath rename
        symlink truncate delete unlink
      ]

          arg_before_path_methods = %i[
        chmod fnmatch fnmatch? lchmod
      ]

          two_args_before_path_methods = %i[chown lchown utime]

          do_not_define_methods = %i[join umask new]

          if arg_methods.include? meth
            define_method(meth) do |*args|
              File.send(meth, @path, *args)
            end
          elsif arg_before_path_methods.include? meth
            define_method(meth) do |*args|
              first_arg = args.shift

              File.send(meth, first_arg, @path, *args)
            end
          elsif two_args_before_path_methods.include? meth
            define_method(meth) do |*args|
              one = args.shift
              two = args.shift

              File.send(meth, one, two, @path, *args)
            end
          elsif do_not_define_methods.include? meth
          else
            define_method(meth) do
              File.send(meth, @path)
            end
          end
        end

        def self.create(path)
          fso = new(path)

          if fso.directory?
            Rosh::Host::FileSystemObjects::LocalDir.new(path)
          elsif fso.file?
            Rosh::Host::FileSystemObjects::LocalFile.new(path)
          elsif fso.symlink?
            Rosh::Host::FileSystemObjects::LocalLink.new(path)
          end
        end

        def initialize(path)
          @path = path
        end

        # Wrapper for #chown that allows setting user/group owner using key/value
        # pairs.  If no value is given for user or group, nothing will be changed.
        #
        # @param [Hash] options
        # @option options [String] :user_name Name of the user to make owner.
        # @option options [Fixnum] :user_uid UID of the user to make owner.
        # @option options [String] :group_name Name of the group to make owner.
        # @option options [Fixnum] :group_uid UID of the group to make owner.
        # @return [Hash{Symbol => Struct::Passwd, Struct::Group}] The owning user
        # and group of the file system object.
        def owner(**options)
          if options.empty?
            return {
              user: Etc.getpwuid(stat.uid),
              group: Etc.getgrgid(stat.gid)
            }
          end

          user_uid = if options[:user_name]
            user = Etc.getpwnam(options[:user_name])
            user.uid
          elsif options[:user_uid]
            options[:user_uid]
          end

          group_uid = if options[:group_name]
            group = Etc.getgrnam(options[:group_name])
            group.gid
          elsif options[:group_uid]
            options[:group_uid]
          end

          if chown(user_uid, group_uid) == 1
            {
              user: Etc.getpwuid(stat.uid),
              group: Etc.getgrgid(stat.gid)
            }
          end
        end

        def to_path
          @path
        end

        def group
          Etc.getgrgid(stat.gid)
        end

        def to_s
          File.basename @path
        end
      end
    end
  end
end

require_relative 'local_dir'
require_relative 'local_file'
require_relative 'local_link'
