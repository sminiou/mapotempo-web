# Copyright © Mapotempo, 2013-2015
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

class DestinationsImport
  include ActiveModel::Model
  include ActiveRecord::AttributeAssignment
  extend ActiveModel::Translation

  attr_accessor :replace, :file
  validates :file, presence: true

  def replace=(value)
    @replace = TRUE_VALUES.include?(value)
  end

  def tempfile
    file.tempfile
  end

  def name
    (file.original_filename || file.filename).split('.')[0..-2].join('.')
  end

  private

  TRUE_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE', 'on', 'ON'].to_set
end
