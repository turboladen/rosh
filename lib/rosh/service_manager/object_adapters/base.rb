class Rosh
  class ServiceManager
    module ObjectAdapters
      module Base
        def self.included(base)
          base.extend ClassMethods
        end

        module ClassMethods
          def service_name=(service_name)
            @service_name = service_name
          end

          def host_name=(host_name)
            @host_name = host_name
          end

          def update_attribute(key, value)
            self.send("#{key}=", value)
          end

          def build_info(status, pid: nil, process_info: nil)
            process_info = if pid
              current_shell.ps(pid: pid)
            elsif process_info
              process_info
            else
              current_shell.ps(name: @service_name)
            end

            if pid #&& !process_info.empty?
              status = :running
            end

            {
              name: @service_name,
              status: status,
              processes: process_info
            }
          end
        end
      end
    end
  end
end
