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
require 'optimizer_job'

class Optimizer

  def self.optimize_each(planning)
    if Mapotempo::Application.config.delayed_job_use
      if planning.customer.job_optimizer
        # Customer already run an optimization
        planning.errors.add(:base, I18n.t('errors.planning.already_optimizing'))
        false
      else
        planning.customer.job_optimizer = Delayed::Job.enqueue(OptimizerJob.new(planning.id, nil))
        planning.customer.job_optimizer.progress = '0;0;0'
        planning.customer.job_optimizer.save!
      end
    else
      planning.select(&:vehicle).each{ |route|
        optimize(planning, route)
      }
    end
  end

  def self.optimize(planning, route)
    if route.size_active <= 1
        # Nothing to optimize
      true
    elsif Mapotempo::Application.config.delayed_job_use
      if planning.customer.job_optimizer
        # Customer already run an optimization
        planning.errors.add(:base, I18n.t('errors.planning.already_optimizing'))
        false
      else
        planning.customer.job_optimizer = Delayed::Job.enqueue(OptimizerJob.new(planning.id, route.id))
        planning.customer.job_optimizer.progress = '0;0;'
        planning.customer.job_optimizer.save!
      end
    else
      optimum = route.optimize(nil) { |matrix|
        tws = [[nil, nil, 0]] + route.stops.select(&:active).collect{ |stop|
          open = stop.destination.open ? Integer(stop.destination.open - route.vehicle.open) : nil
          close = stop.destination.close ? Integer(stop.destination.close - route.vehicle.open) : nil
          if open && close && open > close
            close = open
          end
          take_over = stop.destination.take_over ? stop.destination.take_over : planning.customer.take_over
          take_over = take_over ? take_over.seconds_since_midnight : 0
          [open, close, take_over]
        }
        Ort.optimize(route.vehicle.capacity, matrix, tws, planning.customer.optimization_cluster_size)
      }
      if optimum
        route.order(optimum)
        route.save && route.reload # Refresh stops order
        planning.compute
        planning.save
      else
        false
      end
    end
  end

end
