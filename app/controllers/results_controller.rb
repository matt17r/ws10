class ResultsController < ApplicationController
  include AdminAuthentication

  def link
    event = Event.find(params[:event_id])
    all_positions = (event.finish_positions.pluck(:position) + event.finish_times.pluck(:position)).uniq.sort
    created = []
    skipped = []
    all_positions.each do |position|
      fp = event.finish_positions.find_by(position: position)
      ft = event.finish_times.find_by(position: position)
      next unless fp || ft

      user = fp&.user
      time = ft&.time

      already_linked = user.present? && event.results.exists?(user: user, time: time)

      unless already_linked
        result = event.results.build(user: user, time: time)
        if result.save
          created << position
        else
          skipped << "#{position} (#{result.errors.full_messages.to_sentence})"
        end
      else
        skipped << "#{position} (already linked)"
      end
    end

    if skipped.empty?
      redirect_to dashboard_path, notice: "Linked #{created.count} results successfully."
    else
      redirect_to dashboard_path, alert: "Linked #{created.count} results. Skipped: #{skipped.join(', ')}"
    end
  end

  def destroy
    @result = Result.find(params[:id])

    if @result.destroy
      redirect_to dashboard_path, notice: "Result deleted"
    else
      redirect_to dashboard_path, alert: @result.errors.full_messages.to_sentence
    end
  end

  def destroy_all
    event = Event.find(params[:event_id])
    count = event.results.count

    event.results.destroy_all

    redirect_to dashboard_path, notice: "Deleted #{count} results"
  end
end
