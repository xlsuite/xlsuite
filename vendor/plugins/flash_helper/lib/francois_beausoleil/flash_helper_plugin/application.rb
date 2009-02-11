module FrancoisBeausoleil #:nodoc
  module FlashHelperPlugin #:nodoc
    module ApplicationController
      # Append a warning (failure) message to the Flash, for subsequent display using
      # ApplicationHelper#show_flash_messages.
      #
      # If you pass :now as the first argument, <tt>flash.now</tt> will be used instead of plain <tt>flash</tt>.
      #
      # === Example
      #  if model.update_attributes(params[:model]) then
      #    ...
      #  else
      #    flash_warning(:now, 'Record failed to update')
      #    ...
      #  end
      def flash_warning(*args)
        append_to_flash(:warning, *args)
      end
      alias_method :flash_failure, :flash_warning

      # Append a neutral (reminder, informational) message to the Flash, for subsequent display using
      # ApplicationHelper#show_flash_messages.
      #
      # If you pass :now as the first argument, <tt>flash.now</tt> will be used instead of plain <tt>flash</tt>.
      #
      # === Example
      #  flash_message('Site will be down between 4 and 5 AM today')
      def flash_message(*args)
        append_to_flash(:message, *args)
      end

      # Append a success message to the Flash, for subsequent display using
      # ApplicationHelper#show_flash_messages.
      #
      # If you pass :now as the first argument, <tt>flash.now</tt> will be used instead of plain <tt>flash</tt>.
      #
      # === Example
      #  if model.update_attributes(params[:model]) then
      #    flash_notice('Record updated successfully')
      #    redirect_to ...
      #  else
      #    ...
      #  end
      def flash_notice(*args)
        append_to_flash(:notice, *args)
      end
      alias_method :flash_success, :flash_notice

      # Appends +text+ to the Flash, under +key+.  Key will be symbolized before the Flash is updated.
      # See ApplicationHelper#show_flash_messages for details of how to display these messages.
      #
      # To append to flash.now, send :now as the second argument, as in:
      #  append_to_flash(:message, :now, 'this is the message')
      def append_to_flash(key, *args)
        key = key.to_sym
        now = (:now == args[0])
        obj = now ? args[1] : args[0]

        target = now ? self.flash.now : self.flash
        target[key] = [target[key], obj]
        target[key].flatten!
        target[key].compact!
      end
    end
  end
end
