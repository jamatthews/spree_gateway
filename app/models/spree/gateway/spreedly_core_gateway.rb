module Spree
  class Gateway::SpreedlyCoreGateway < Gateway
    preference :login, :string
    preference :password, :string
    preference :gateway_token, :string


    CARD_TYPE_MAPPING = {
      'American Express' => 'american_express',
      'Diners Club' => 'diners_club',
      'Visa' => 'visa',
      'MasterCard' => 'master'
    }


    def provider_class
      ActiveMerchant::Billing::SpreedlyCoreGateway
    end

    def method_type
      'spreedly_core'
    end
    
    def payment_profiles_supported?
      true
    end

    def purchase(money, creditcard, gateway_options)
      provider.purchase(*options_for_purchase_or_auth(money, creditcard, gateway_options))
    end

    def authorize(money, creditcard, gateway_options)
        provider.authorize(*options_for_purchase_or_auth(money, creditcard, gateway_options))
    end

    def capture(money, response_code, gateway_options)
      provider.capture(money, response_code, gateway_options)
    end

    def credit(money, creditcard, response_code, gateway_options)
      provider.refund(money, response_code, {})
    end

    def void(response_code, creditcard, gateway_options)
      provider.void(response_code, {})
    end

    def create_profile(payment)
      if payment.source.gateway_customer_profile_id.nil?
        payment.source.update_attributes({
          :gateway_customer_profile_id => :gateway_payment_profile_id
        })
      end
    end

    private

    def options_for_purchase_or_auth(money, creditcard, gateway_options)
      options = {}
      options[:description] = "Spree Order ID: #{gateway_options[:order_id]}"
      options[:currency] = gateway_options[:currency]
      options[:store] = true
      

      if customer = creditcard.gateway_customer_profile_id
        options[:customer] = customer
      end
      if token_or_card_id = creditcard.gateway_payment_profile_id
        # The Stripe ActiveMerchant gateway supports passing the token directly as the creditcard parameter
        # The Stripe ActiveMerchant gateway supports passing the customer_id and credit_card id
        # https://github.com/Shopify/active_merchant/issues/770
        creditcard = token_or_card_id
      end
      return money, creditcard, options
    end
  end 
end