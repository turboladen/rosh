require 'drama_queen/publisher'


class Rosh
  module Command
    include DramaQueen::Publisher

    def run_command(idempotency_check=nil, &cmd_block)
      if current_host.idempotent_mode? && idempotency_check.call
        # probably should return something here, no?
        return
      end

      cmd_result = cmd_block.call
      publish 'rosh.command_results', cmd_result

      cmd_result.ruby_object
    end
  end
end
