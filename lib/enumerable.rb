
module Enumerable
  ##
  # Syntatic sugar.  This idiom:
  # snap.print_list.items.inject(Context.new(@options)) { |context, item| item.print(context) }.done
  # becomes
  # snap.print_list.items.print_list(Context.new(@options))
  # if the enumerable produces items.  If it produces something else
  # (like the hash name of an item) then a block can be specified
  # like:
  # attributes.ctl_chan.value.split(',').print_list(context.nest) do |context, adapter_name|
  #   @db.devices[adapter_name].print(context)
  # end
  def print_list(context, &proc)
    if block_given?
      inject(context, &proc).done
    else
      inject(context) { |context, item| item.print(context) }.done
    end
  end
end
