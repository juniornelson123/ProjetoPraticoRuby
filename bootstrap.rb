class Payment
  attr_reader :authorization_number, :amount, :invoice, :order, :payment_method, :paid_at

  def initialize(attributes = {})
    @authorization_number, @amount = attributes.values_at(:authorization_number, :amount)
    @invoice, @order = attributes.values_at(:invoice, :order)
    @payment_method = attributes.values_at(:payment_method)
  end

  def pay(paid_at = Time.now)
    purchase = Purchase.new(order)
    @amount = order.total_amount
    @authorization_number = Time.now.to_i
    @invoice = Invoice.new(billing_address: order.address, shipping_address: order.address, order: order)
    @paid_at = paid_at
    order.close(@paid_at)
  end

  def paid?
    !paid_at.nil?
  end


end

class Invoice
  attr_reader :billing_address, :shipping_address, :order

  def initialize(attributes = {})
    @billing_address = attributes.values_at(:billing_address)
    @shipping_address = attributes.values_at(:shipping_address)
    @order = attributes.values_at(:order)
  end
end

class Order
  attr_reader :customer, :items, :payment, :address, :closed_at

  def initialize(customer, overrides = {})
    @customer = customer
    @items = []
    @order_item_class = overrides.fetch(:item_class) { OrderItem }
    @address = overrides.fetch(:address) { Address.new(zipcode: '45678-979') }
  end

  def add_product(product)
    @items << @order_item_class.new(order: self, product: product)
  end

  def total_amount
    @items.map(&:total).inject(:+)
  end

  def close(closed_at = Time.now)
    @closed_at = closed_at
  end

  def generate_shipping_label
    puts "generate shipping label to send"
  end
  # remember: you can create new methods inside those classes to help you create a better design
end

class OrderItem
  attr_reader :order, :product

  def initialize(order:, product:)
    @order = order
    @product = product
  end

  def total
    10
  end
end

class Product
  # use type to distinguish each kind of product: physical, book, digital, membership, etc.
  attr_reader :name, :type

  def initialize(name:, type:)
    @name, @type = name, type
  end
end

class Address
  attr_reader :zipcode

  def initialize(zipcode:)
    @zipcode = zipcode
  end
end

class CreditCard
  def self.fetch_by_hashed(code)
    CreditCard.new
  end
end

class Customer
  attr_reader :membership

  def initialize(attributes = {})
    @membership = Membership.new
  end

  # you can customize this class by yourself
end

class Membership
  attr_reader :status

  def initialize
    @status = false
  end

  def update(status)
    @status = status
    puts "membership active(true)"
  end
  # you can customize this class by yourself
end

class Purchase
  attr_reader :order

  def initialize(order)
    @order = order
    verify_order
  end
  
  def verify_order
    @order.items.each do |item|
      case item.product.type
        when :physical
          purchase_physical
        when :book
          purchase_book
        when :digital
          purchase_digital
        when :membership
          purchase_membership
        else
          puts "Invalid option to item"
        end
    end
  end

  def purchase_physical
    @order.generate_shipping_label
  end

  def purchase_book
    @order.generate_shipping_label
    notification = Notification.new('Book', "Buy Book Notification")
    notification.send_notification
  end

  def purchase_digital
    notification = Notification.new('Digital', "Buy Digital Notification")
    notification.send_notification
    voucher = Voucher.new(10)
    voucher.generate_voucher
  end

  def purchase_membership
    @order.customer.membership.update true
    notification = Notification.new('Membership', "Buy Membership Notification")
    notification.send_notification
  end
end

class Voucher
  attr_reader :value

  def initialize(value)
    @value = value
  end

  def generate_voucher
    puts "generate discount #{value}%"
  end
end

class Notification
  attr_reader :title, :body

  def initialize(title, body)
    @title = title  
    @body = body  
  end

  def send_notification 
    puts "title notification: #{@title}"
    puts "body notification: #{@body}"
  end
end

# Book Example (build new payments if you need to properly test it)
foolano = Customer.new
# book = Product.new(name: 'Awesome book', type: :physical) #item physical
# book = Product.new(name: 'Awesome book', type: :book) #item book
book = Product.new(name: 'Awesome book', type: :membership) #item membership
# book = Product.new(name: 'Awesome book', type: :digital) #item digital
book_order = Order.new(foolano)
book_order.add_product(book)

payment_book = Payment.new(order: book_order, payment_method: CreditCard.fetch_by_hashed('43567890-987654367'))
payment_book.pay
p payment_book.paid? # < true
p payment_book.order.items.first.product.type

# now, how to deal with shipping rules then?