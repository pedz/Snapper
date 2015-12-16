require_relative "command_line_option"

command_line_option do |snapper, options|
  cmd = ->(batch, options) do
    batch.snap_list[0].db.keys.sort.each do |key|
      klass = batch.snap_list[0].db[key]
      if klass.is_a? Array
        klass.each_index do |index|
          klass[index].flat_keys([key, index]).each do |k, v|
            options.puts("#{k}:#{v}")
          end
        end
      else
        klass.flat_keys([key]).each do |k, v|
          options.puts("#{k}:#{v}")
        end
      end
    end
  end

  options.on("--flat-keys",
             "Print the flat_keys and value of the entire",
             "database from the first snap.") do |fk|
    options.add_cmd(cmd)
  end
end
