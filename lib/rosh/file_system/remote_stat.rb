class Rosh
  class FileSystem
    class RemoteStat < Struct.new(:dev, :ino, :mode, :nlink, :uid, :gid, :rdev,
      :size, :blksize, :blocks, :atime, :mtime, :ctime)
    end
  end
end
