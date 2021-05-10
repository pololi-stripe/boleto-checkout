# Accept a Card Payment

Stripe Checkout is the fastest way to get started with payments. Included are some basic build and run scripts you can use to start up the application.

## Demo link
https://boleto-checkout.herokuapp.com  

Note: for test mode, you can use `000.000.000-00` for CNPJ/CPF field

## Running the sample

1. Build the server

```
bundle install
```

2. Make a copy `.env.template` to `.env` and update the file with your Stripe API keys

3. Run the server

```
ruby server.rb
```

4. Go to [http://localhost:4242](http://localhost:4242)
