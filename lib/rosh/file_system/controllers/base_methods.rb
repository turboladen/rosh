require_relative '../../string_refinements'


class Rosh
  class FileSystem
    module Controllers
      # TODO: Add IO methods?
      module BaseMethods

        # @return [String] The path that was used to initialize the object.
        attr_reader :path

        def symlink(new_path, watched_object)
          does_not_exist_before = adapter.exists?
          adapter.symlink(new_path)

          if does_not_exist_before
            watched_object.changed
            watched_object.notify_observers(watched_object,
              attribte: :symbolic_link,
              old: nil, new: new_path, as_sudo: nil
            )
          end

          0
        end

        def truncate(new_length, watched_object)
          old_length = adapter.size
          adapter.truncate(new_length)

          if old_length != new_length
            watched_object.changed
            watched_object.notify_observers(watched_object,
              attribute: :size,
              old: old_length, new: new_length, as_sudo: nil
            )
          end

          0
        end

        def utime(access_time, modification_time, watched_object)
          old_atime = adapter.atime
          old_mtime = adapter.mtime
          adapter.utime(access_time, modification_time)

          if old_atime != access_time
            watched_object.changed
            watched_object.notify_observers(watched_object,
              attribute: :access_time,
              old: old_atime, new: access_time, as_sudo: nil
            )
          end

          if old_mtime != modification_time
            watched_object.changed
            watched_object.notify_observers(self,
              attribute: :modification_time,
              old: old_mtime, new: modification_time, as_sudo: nil
            )
          end
        end

        def flock(lock_types)
          adapter.flock(lock_types)
        end
      end
    end
  end
end
