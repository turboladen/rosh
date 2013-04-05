class Rosh
  class LocalFileSystemObject
    File.singleton_methods.each do |meth|
      arg_methods = %i[
        identical? basename expand_path link new open realdirpath realpath rename
        symlink truncate delete unlink
      ]

      arg_before_path_methods = %i[
        chmod fnmatch fnmatch? lchmod
      ]

      two_args_before_path_methods = %i[chown lchown utime]

      do_not_define_methods = %i[join umask]

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
        Rosh::LocalDir.new(path)
      elsif fso.file?
        Rosh::LocalFile.new(path)
      elsif fso.symlink?
        Rosh::LocalLink.new(path)
      end
    end

    def initialize(path)
      @path = path
    end
  end
end

require_relative 'local_dir'
require_relative 'local_file'
require_relative 'local_link'
