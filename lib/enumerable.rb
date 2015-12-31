
module Enumerable
  # Syntatic sugar.  For an Enumberable whose {Enumerable#inject} method yields
  # {Item}s (e.g. an array of {Item}s, the original code of:
  #
  #   snap.print_list.items.inject(context) { |context, item| item.print(context) }.done
  #
  # becomes
  #
  #   snap.print_list.items.print(context)
  #
  # If the {Enumerable}s {Enumerable#inject} method produces something else
  # (like the hash name of an item) then a block can be specified
  # like:
  #
  #   attributes.ctl_chan.value.split(',').print(context.nest) do |context, adapter_name|
  #     @db.devices[adapter_name].print(context)
  #   end
  #
  # @param context [Context] The context to pass to each item's
  #   {Print#print} routine.
  # @param proc [Proc] Optional proc.
  # @yieldparam context [Context] The contexted passed in.
  # @yieldparam item [Object] Each item in the enumeration.
  # @yieldreturn [Context] Inject is used so the context (perhaps
  #   altered) must be returned from the proc.
  def print(context, &proc)
    context.start_list
    if proc.nil?
      inject(context) { |context, item| item.print(context) }.done
    else
      inject(context, &proc).done
    end
    context
  end
end
