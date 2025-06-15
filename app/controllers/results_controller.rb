class ResultsController < ApplicationController
  def link
    event = Event.find(params[:event_id])
    matched_positions = event.finish_positions.pluck(:position) & event.finish_times.pluck(:position)
    created = []
    skipped = []
    matched_positions.each do |position|
      fp = event.finish_positions.find_by(position: position)
      ft = event.finish_times.find_by(position: position)
      next unless fp && ft

      unless event.results.exists?(user: fp.user, time: ft.time)
        result = event.results.build(user: fp.user, time: ft.time)
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
end
