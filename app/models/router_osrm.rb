# Copyright © Mapotempo, 2014-2015
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
require 'osrm'

class RouterOsrm < Router
  validates :url, presence: true

  def trace(lat1, lng1, lat2, lng2)
    Osrm.compute(url, lat1, lng1, lat2, lng2)
  end

  def matrix(vector, &block)
    if true
      # Engine support matrix computation
      vector = pack_vector(vector)
      matrix = Osrm.matrix(url, vector)
      matrix = unpack_vector(vector, matrix)
      matrix.map{ |row|
        row.map{ |v| [v, v] }
      }
    else
      total = positions**2
      vector.collect{ |v1|
        vector.collect{ |v2|
          distance, time, _trace = Osrm.compute(url, v1[0], v1[1], v2[0], v2[1])
          block.call(1, total) if block
          [distance, time]
        }
      }
    end
  end
end
