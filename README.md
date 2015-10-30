# PaycorpRails
[![Gem Version](https://badge.fury.io/rb/paycorp_rails.svg)](https://badge.fury.io/rb/paycorp_rails)

This gem will integrate the Paycorp payment gateway with your Rails app. If you face any issues, place them here : [github.com/LeafyCode/paycorp_rails/issues](https://github.com/LeafyCode/paycorp_rails/issues). You can also contact us directly : [leafycode.com/contact](http://leafycode.com/contact)

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'paycorp_rails'
```

And then execute:

```
$ bundle
```

Or install it yourself as:

```
$ gem install paycorp_rails
```

## Usage
### Initialize the Gateway
To initialize the gateway, in your `config/application.rb` place the following code and make the necessary changes :

```
config.after_initialize do
    paycorp_options = {
        client_id: 'CLIENT_ID',
        hmac: 'HMAC',
        auth_token: 'AUTH_TOKEN',
        endpoint: 'ENDPOINT'
    }
    ::PAYCORP_GATEWAY = PaycorpRails.new(paycorp_options)
end
```

Note : The `CLIENT_ID`, `HMAC`, `AUTH_TOKEN` and the `ENDPOINT` will be given to you by Paycorp.

### Initiate Payment
First, you need to send the transaction details to Paycorp and initiate the payment :

```
payment_options = {
    msg_id: SecureRandom.uuid, # Better generate this and store in the model and then use that in here
    amount: AMOUNT_IN_CENTS,
    currency: 'LKR', # Currency
    return_url: "RETURN_URL",
    user_id: USER_ID, # For reference
    css_url: 'ADDITIONAL_CSS'
}

response = PAYCORP_GATEWAY.initiate_payment(payment_options)
```

**amount** should be in cents. **css_url** : If you are using the iframe version, you can pass a css file to style the iframe. Make sure the file is served with HTTPS.

Store the `response` data in the model (Specially the `reqid` and the `paymentPageUrl`)

If you use the iframe method, use the `paymentPageUrl` for the iframe. If not, redirect the user to that url.

### Complete Payment
When the user complete the order, the Gateway will redirect to the `return_url` you provided earlier. The gateway will post some data to this url. Capture them and store the necessary ones. You can pick the right order using the `reqid` they send like this :

```
Order.find_by(reqid: params[:reqid])
```

Now the payment is ready to process but it's not complete and the user haven't been charged. You need to send a request to Paycorp and tell them to complete the order :

```
payment_options = {
    msg_id: @order.msg_id, # Change @order as necessary
    reqid: @order.reqid
}

response = PAYCORP_GATEWAY.complete_payment(payment_options)
```

Store the necessary information in the `response`. If the returned `responseCode` (`response['responseData']['responseCode']`) is `00`, the order is successful! Otherwise, there's an issue. You can find the response text in the response.

**Warning** When on testing, Paycorp will change the response code according to the amount of cents in your transaction amount. If you want to see a failing transaction, send a non 0 value as cents.

For example, if the order's amount is 100.00, the response code will be `00`. If the amount is 100.01, the response code will be `01`. This happens only during development.

## Development
After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake false` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing
Bug reports and pull requests are welcome on GitHub at [https://github.com/LeafyCode/paycorp_rails](https://github.com/LeafyCode/paycorp_rails). This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Built by

[LeafyCode.com](http://leafycode.com/)
