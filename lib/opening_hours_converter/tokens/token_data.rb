require 'opening_hours_converter/utils/constants'
require 'opening_hours_converter/utils/utils'

module OpeningHoursConverter
  class TokenData
    include Constants
    include Utils
    attr_accessor :years, :months, :weeks

    def initialize
      @years = []
      @months = []
      @weeks = []
    end

    def valid?
      return months.length == 0 && days.length == 0 if weeks.length >= 1

      # return unless months.all? do |month|
      #   if month[:days] && month[:days].length > 0
      #     OSM_MONTHS.include?(month[:month])
      #   else
      #     OSM_MONTHS.include?(month[:from][:month]) && OSM_MONTHS.include?(month[:to][:month])
      #   end
      # end

      return true
    end

    # def complete?
    #   valid? && (months.length >= 1) || (weeks.length >= 1)
    # end

    def weeks?
      complete? && weeks.length >= 1
    end

    def periods?
      true
    end

    def create_period(from, to, year_available)
      binding.pry

      from = Date.new(from[:year], from[:month], from[:day] || 1)
      to = Date.new(to[:year], to[:month], to[:day] || last_day_of(to[:month], to[:year]))
      Period.new(from, to, year_available)
    end

    def create_periods
      if years.length > 1
        years.map do |year|
          (year[:from]..year[:to]).map do |range_year|
            create_period_with({ from: range_year, to: range_year }, months, true)
          end
        end.flatten
      elsif years.length == 1
        create_period_with(years.first, months, true).flatten
      else
        create_period_with({ from: Date.now.year, to: Date.now.year }, months, false).flatten
      end
    end

    def create_period_with year, months, year_known
      months.map do |month|
        if month[:days] && month[:days].length > 0
          month[:days].map do |day|
            create_period({
              year: year[:from],
              month: month[:from],
              day: day[:from]
            }, {
              year: year[:to],
              month: month[:to],
              day: day[:to]
            }, year_known)
          end
        else
          create_period({
            year: year[:from],
            month: month[:from][:month],
            day: month[:from][:day]
          }, {
            year: year[:to],
            month: month[:to][:month],
            day: month[:to][:day]
          }, year_known)
        end
      end
    end

    def create_weeks
      if years.length > 0
        years.map do |year|
          (year[:from]..year[:to]).map do |range_year|
            create_week_with(range_year, weeks, true)
          end
        end.flatten
      else
        create_week_with(Date.now.year, weeks, false)
      end
    end

    def create_week_with(year, weeks, year_known)
      weeks.map do |week|
        if week.key?(:modifier) && week[:modifier] > 1
          (week[:from]..week[:to]).each_with_index do |week_index, index|
            next unless index % week[:modifier] == 0

            Week.new(year, week_index, year_known)
          end
        else
          (week[:from]..week[:to]).each do |week_index|
            Week.new(year, week_index, year_known)
          end
        end
      end
    end

    def to_date_range_list
      if periods?
        PeriodList.new(
          create_periods
        )
      elsif weeks?
        WeekList.new(
          create_weeks
        )
      end
    end
  end
end
