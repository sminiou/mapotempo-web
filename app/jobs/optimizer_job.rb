# Copyright © Mapotempo, 2013-2014
#
# This file is part of Mapotempo.
#
# Mapotempo is free software. You can redistribute it and/or
# modify since you respect the terms of the GNU Affero General
# Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Mapotempo is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the Licenses for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Mapotempo. If not, see:
# <http://www.gnu.org/licenses/agpl.html>
#
require 'ort'

class OptimizerJob < Struct.new(:planning_id, :route_id)
  @@optimize_time = Mapotempo::Application.config.optimize_time

  def perform
    Delayed::Worker.logger.info "OptimizerJob planning_id=#{planning_id} perform"
    routes = route_id ? Route.where(id: route_id, planning_id: planning_id) : Route.where(planning_id: planning_id)
    routes_size = routes.length - 1
    routes_count = 0
    routes.select{ |route|
      route.vehicle && route.size_active > 1
    }.each{ |route|
      customer = route.planning.customer
      i = ii = 0
      optimum = route.optimize(Proc.new { |computed, count|
        i += computed
        if i > ii + 50
          customer.job_optimizer.progress = "#{i * 100 / count};0;" + (routes_size > 1 ? "#{routes_count}/#{routes_size}" : '')
          customer.job_optimizer.save
          Delayed::Worker.logger.info "OptimizerJob planning_id=#{planning_id} #{customer.job_optimizer.progress}"
          ii = i
        end
      }) { |matrix|
        customer.job_optimizer.progress = '100;0;' + (routes_size > 1 ? "#{routes_count}/#{routes_size}" : '')
        customer.job_optimizer.save
        Delayed::Worker.logger.info "OptimizerJob planning_id=#{planning_id} #{customer.job_optimizer.progress}"

        # Optimize
        customer.job_optimizer.progress = "100;#{@@optimize_time}ms#{routes_count};" + (routes_size > 1 ? "#{routes_count}/#{routes_size}" : '')
        customer.job_optimizer.save
        Delayed::Worker.logger.info "OptimizerJob planning_id=#{planning_id} #{customer.job_optimizer.progress}"
        tws = [[nil, nil, 0]] + route.stops.select(&:active).collect{ |stop|
          open = stop.destination.open ? Integer(stop.destination.open - route.vehicle.open) : nil
          close = stop.destination.close ? Integer(stop.destination.close - route.vehicle.open) : nil
          if open && close && open > close
            close = open
          end
          take_over = stop.destination.take_over ? stop.destination.take_over : customer.take_over
          take_over = take_over ? take_over.seconds_since_midnight : 0
          [open, close, take_over]
        }
        optimum = Ort.optimize(route.vehicle.capacity, matrix, tws, route.planning.customer.optimization_cluster_size)
        customer.job_optimizer.progress = '100;100;' + (routes_size > 1 ? "#{routes_count}/#{routes_size}" : '')
        customer.job_optimizer.save
        Delayed::Worker.logger.info "OptimizerJob planning_id=#{planning_id} #{customer.job_optimizer.progress}"
        optimum
      }

      # Apply result
      if optimum
        route.order(optimum)
        route.save && route.reload # Refresh stops order
        route.planning.compute
        route.planning.save
        customer.save
      end

      routes_count += 1
    }
  end
end
