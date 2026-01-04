module HomeStatistics
  extend ActiveSupport::Concern

  class_methods do
    def home_statistics
      Rails.cache.fetch("home_statistics") do
        calculate_home_statistics
      end
    end

    def invalidate_home_statistics_cache
      Rails.cache.delete("home_statistics")
    end

    private

    def calculate_home_statistics
      {
        confirmed_registrations: confirmed_registrations_count,
        total_participants: total_participants_count,
        unique_participants: unique_participants_count,
        fastest_time: overall_fastest_time,
        average_time: overall_average_time,
        median_time: overall_median_time,
        location_statistics: location_statistics_data,
        total_kilometres: total_kilometres_run,
        total_time_seconds: total_time_spent_running
      }
    end

    def confirmed_registrations_count
      User.where.not(confirmed_at: nil).count
    end

    def total_participants_count
      Result.count + Volunteer.count
    end

    def unique_participants_count
      User.joins("LEFT JOIN results ON results.user_id = users.id")
          .joins("LEFT JOIN volunteers ON volunteers.user_id = users.id")
          .where("results.id IS NOT NULL OR volunteers.id IS NOT NULL")
          .distinct
          .count
    end

    def location_statistics_data
      Location.includes(events: :results).map do |location|
        times = location.events.joins(:results)
                       .where.not(results: { time: nil })
                       .pluck("results.time")

        next if times.empty?

        sorted_times = times.sort
        total_participants = location.events.joins(:results).count + location.events.joins(:volunteers).count

        {
          location: location,
          quickest_time: sorted_times.first,
          average_time: (times.sum.to_f / times.size).round,
          median_time: sorted_times[sorted_times.size / 2],
          total_participants: total_participants
        }
      end.compact
    end

    def overall_fastest_time
      Result.where.not(time: nil).minimum(:time)
    end

    def overall_average_time
      times = Result.where.not(time: nil).pluck(:time)
      return nil if times.empty?
      (times.sum.to_f / times.size).round
    end

    def overall_median_time
      times = Result.where.not(time: nil).order(:time).pluck(:time)
      return nil if times.empty?
      times[times.size / 2]
    end

    def total_kilometres_run
      Result.where.not(time: nil).count * 10
    end

    def total_time_spent_running
      Result.where.not(time: nil).sum(:time)
    end
  end
end
