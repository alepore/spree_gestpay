module Spree
  class Gateway::Gestpay < Gateway
    def supports?(source)
      true
    end

    def auto_capture?
      false
    end

    def provider_class
      provider.class
    end

    def provider
      self
    end

    def actions
      %w(capture void)
    end

    # Indicates whether its possible to capture the payment
    def can_capture?(payment)
      ['pending'].include?(payment.state)
    end

    # Indicates whether its possible to void the payment.
    def can_void?(payment)
      payment.state != 'void'
    end
    #######################################################################

    def capture(*_args)
      ActiveMerchant::Billing::Response.new(true, '', {}, {})
    end

    def void(*_args)
      ActiveMerchant::Billing::Response.new(true, '', {}, {})
    end

    def process_payment_result(result)
      Rails.logger.warn "Gestpay Result: #{result.inspect}"
      order = Spree::Order.find_by_number(result.shop_transaction_id)
      Rails.logger.warn "Processing payment results for order id #{ order.id }: #{ order.state } | #{ order.number }"

      # TODO: Add a transaction?
      # Spree::Order.transaction do ... end

      # this check is needed because this method is called twice during the iframe checkout process
      if order.state == 'complete'
        return order.payments.last
      end

      if order.state == 'payment'
        account = nil
        # try will not raise in Rails 4 if the 'token' method does not exists. Rails 3 will.
        # result will not respond_to token, so we have to skip this check.
        begin
          if result.token.present?
            if user = order.user
              account = Spree::GestpayAccount.new
              account.user = user
              account.token = result.token
              account.month = result.token_expiry_month
              account.year = result.token_expiry_year
              account.save
              if user && user.gestpay_accounts.size == 1
                user.update_attributes(
                  preferred_payment_method_id: Spree::Config[:payment_method_gestpay_account_id],
                  preferred_gestpay_account_index: 0
                )
              end

              Rails.logger.warn "GestPay Account saved #{ account.id }"
            end
          end
        rescue => e
          Rails.logger.warn 'GestPay token not valid, skipping saving account'
        end

        payment = order.payments.build(
          amount: result.amount,
          payment_method_id: id
        )
        payment.source = account
        payment.started_processing!

        Rails.logger.warn "Processing payment #{ payment.id }"

        Rails.logger.warn "Updating order state: from #{order.state}"
        if result.success? && order.next
          payment.pend!
          Rails.logger.warn "Updating order state: to #{order.state}"
          Rails.logger.warn "Updating order state: finalized: #{order.state}"
        else
          payment.failure!
        end

        Rails.logger.warn "Payment processed #{ payment.id } (#{ payment.state }) for order #{ payment.order.number } (#{payment.order.state})"

        return payment
      end
    end
  end
end
