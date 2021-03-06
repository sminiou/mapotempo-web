csv << [
    I18n.t('order_arrays.export_file.name'),
    I18n.t('order_arrays.export_file.comment'),
] + @order_array.days.times.collect { |i|
  l @order_array.base_date + i
} + @order_array.customer.products.collect(&:code) + [
  I18n.t('order_arrays.export_file.total')
]

sum_column = Hash.new { |h,k| h[k] = {} }
@order_array.destinations_orders.collect { |destination_orders|
  sum = {}
  total = 0
  csv << [
    destination_orders[0].destination.name,
    destination_orders[0].destination.comment,
  ] + destination_orders.collect { |order|
    order.products.each { |product|
      sum_column[order.shift][product] = (sum_column[order.shift][product] || 0) + 1
      sum[product] = (sum[product] || 0 ) + 1
    }
    order.products.collect(&:code).join('/')
  } + @order_array.customer.products.collect{ |product|
    total += sum[product] || 0
    sum[product]
  } + [
    total > 0 ? total : nil
  ]
}

total_column = []
grand_total = Hash.new { |h,k| h[k] = 0 }
shift = 0
@order_array.customer.products.each { |product|
  csv << [
    product.code,
    product.name,
  ] + @order_array.days.times.collect { |i|
    total_column[i] = sum_column[i][product] ? (total_column[i] || 0) + sum_column[i][product] : total_column[i]
    grand_total[product] += sum_column[i][product] || 0
    sum_column[i][product]
  } + [nil] * shift + [grand_total[product] > 0 ? grand_total[product] : nil]
  shift += 1
}

csv << [
  I18n.t('order_arrays.export_file.total'),
  nil,
] + @order_array.days.times.collect { |i|
  total_column[i]
} + [nil] * @order_array.customer.products.size + [grand_total.values.sum]
