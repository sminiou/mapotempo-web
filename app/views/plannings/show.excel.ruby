CSV.generate({col_sep: ';'}) { |csv|
  csv << [
    I18n.t('plannings.export_file.vehicle'),
    I18n.t('plannings.export_file.route'),
    I18n.t('plannings.export_file.order'),
    I18n.t('plannings.export_file.wait_time'),
    I18n.t('plannings.export_file.time'),
    I18n.t('plannings.export_file.distance'),
    I18n.t('plannings.export_file.ref'),
    I18n.t('plannings.export_file.name'),
    I18n.t('plannings.export_file.street'),
    I18n.t('plannings.export_file.detail'),
    I18n.t('plannings.export_file.postalcode'),
    I18n.t('plannings.export_file.city'),
    I18n.t('plannings.export_file.lat'),
    I18n.t('plannings.export_file.lng'),
    I18n.t('plannings.export_file.comment'),
    I18n.t('plannings.export_file.take_over'),
    @planning.customer.enable_orders ? I18n.t('plannings.export_file.orders') : I18n.t('plannings.export_file.quantity'),
    I18n.t('plannings.export_file.active'),
    I18n.t('plannings.export_file.open'),
    I18n.t('plannings.export_file.close'),
    I18n.t('plannings.export_file.tags'),
    I18n.t('plannings.export_file.out_of_window'),
    I18n.t('plannings.export_file.out_of_capacity'),
    I18n.t('plannings.export_file.out_of_drive_time')
  ]
  @planning.routes.select { |route|
    !route.vehicle || route.stops.size > 0
  }.collect { |route|
    render partial: 'routes/show', formats: [:csv], locals: {route: route, csv: csv}
  }.join('')
}
