require_relative "snapper"

# An example of a command that is added separately.  This creates and
# implements the --flat-keys command line option.
class FlatKeysCmd < Snapper
  add_command_line_option do |snapper, options|
    flat_keys_cmd = ->(batch, options) do
      batch.cec_list.each do |cec|
        cec.lpars.each do |lpar|
          lpar.snaps.each do |snap|
            snap.db.keys.sort.each do |key|
              klass = snap.db[key]
              if klass.is_a?(Array)
                klass.each_index do |index|
                  klass[index].flat_keys([cec.id_to_system, lpar.hostname, snap.date_time, key, index]).each do |k, v|
                    options.puts("#{k}:#{v}")
                  end
                end
              else
                klass.flat_keys([cec.id_to_system, lpar.hostname, snap.date_time, key]).each do |k, v|
                  options.puts("#{k}:#{v}")
                end
              end
            end
          end
        end
      end
    end

    options.on("--flat-keys",
               "Print the flat_keys and value of the entire",
               "database from the first snap.") do |fk|
      options.add_cmd(flat_keys_cmd) if fk
    end
  end
  # @param  remove me
end
