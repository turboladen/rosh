require 'forwardable'


class Rosh
  class FileSystem

    # Defines File::Stat methods on including objects.  The includer must define
    # `#controller`, as all methods will delegate to the object returned by
    # that method.
    module StatMethods
      extend Forwardable

      %i[exists? <=>
        blksize blockdev? blocks chardev? dev dev_major dev_minor
        directory? executable? executable_real? file? gid grpowned?
        ino mode nlink owned? pipe?
        rdev rdev_major rdev_minor
        readable? readable_real?
        setgid? setuid?
        size
        socket? sticky? symlink? uid
        world_readable? world_writable? writable? writable_real?
        zero?].sort.each do |meth|
        define_method(meth) do
          Rosh._run_command(method(__method__), &adapter.method(__method__).to_proc)
        end
      end

      alias_method :block_size, :blksize
      alias_method :block_device?, :blockdev?
      alias_method :character_device?, :chardev?
      alias_method :device, :dev
      alias_method :device_major, :dev_major
      alias_method :device_minor, :dev_minor
      alias_method :group_id, :gid
      alias_method :group_owned?, :grpowned?
      alias_method :inode, :ino
      alias_method :hard_link_count, :nlink
      alias_method :set_group_id?, :setgid?
      alias_method :set_user_id?, :setuid?
      alias_method :symbolic_link?, :symlink?
      alias_method :user_id, :uid
    end
  end
end
