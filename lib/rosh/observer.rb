class Rosh
  module Observer
    def update(obj, attribute, old_value, new_value, as_sudo)
      puts "I' a #{self.class} and I got updated!"
      puts attribute
      puts old_value
      puts new_value
      puts as_sudo

      changed
      notify_observers(obj,
        attribute,
        old_value,
        new_value,
        as_sudo
                      )
    end
  end
end
