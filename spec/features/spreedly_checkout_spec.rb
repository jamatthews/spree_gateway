require 'spec_helper'

describe "Spreedly Checkout" do
  let!(:country) { create(:country, :states_required => true) }
  let!(:state) { create(:state, :country => country) }
  let!(:shipping_method) { create(:shipping_method) }
  let!(:stock_location) { create(:stock_location) }
  let!(:mug) { create(:product, :name => "RoR Mug") }
  let!(:spreedly_payment_method) do
    Spree::Gateway::SpreedlyCoreGateway.create!(
        :name => "Spreedly",
        :preferred_login => "XkPaiYB41TJBdW7yja3hOt09og0",
        :preferred_password => "apho4vNN6cuJeE4X4qsBs4TATP4xywUuNfexPa4l8r3J7Kmwh1LDNQ41lYhg7BLe",
        :preferred_gateway_token => "sJZqKWNFHLChJCyNVAAt56COHn",
        :environment => "test"
    )
  end

  let!(:zone) { create(:zone) }

  before do
    user = create(:user)

    order = OrderWalkthrough.up_to(:delivery)
    order.stub :confirmation_required? => true

    order.reload
    order.user = user
    order.update!

    Spree::CheckoutController.any_instance.stub(:current_order => order)
    Spree::CheckoutController.any_instance.stub(:try_spree_current_user => user)
    Spree::CheckoutController.any_instance.stub(:skip_state_validation? => true)

    visit spree.checkout_state_path(:payment)
  end

  # This will fetch a token from Spreedly and then pass that to the webserver.
  # The server then processes the payment using that token.
  it "can process a valid payment (with JS)", :js => true do
    fill_in "First name", :with => "Test"
    fill_in "Last name", :with => "Test"

    Capybara.within_frame 'spreedly-iframe' do
      fill_in "Credit Card Number", :with => "4111111111111111"
      fill_in "CVV", :with => "123"

    end

    fill_in "month", :with => "01"
    fill_in "year", :with => "#{Time.now.year + 1}"

    click_button "Save and Continue"
    page.should have_content("Billing Address (Edit)")
    page.current_url.should include("/checkout/confirm")
    click_button "Place Order"
    page.should have_content("Your order has been processed successfully")
  end
end