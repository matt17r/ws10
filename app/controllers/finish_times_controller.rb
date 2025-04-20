class FinishTimesController < ApplicationController
  def import
    if params[:file].present?
      created = 0
      skipped = 0
      errors = 0
      # ## Sample Data
      # STARTOFEVENT, 20/04/2025 07:00:23, virtual_volunteer_ios_2.3.0_85
      # 0,            20/04/2025 07:00:23,
      # 1,            20/04/2025 07:35:24, 00:35:00
      # 2,            20/04/2025 07:58:25, 00:58:01
      # 3,            20/04/2025 08:10:07, 01:09:43
      # ENDOFEVENT,   20/04/2025 08:12:51,
      CSV.foreach(params[:file], headers: false) do |row|
        if [ "STARTOFEVENT", "0", "ENDOFEVENT" ].include? row[0]
          skipped += 1
          next
        end

        finish_time = FinishTime.create({
            event_id: params[:event_id],
            position: row[0],
            time_string: row[2]
          })

        if finish_time.persisted?
          created += 1
        else
          puts finish_time.errors
          errors += 1
        end
      end
      redirect_to dashboard_path, notice: "#{created} finish times imported (#{errors} errors)."
    else
      redirect_to dashboard_path, alert: "No file selected/uploaded."
    end
  end

  def destroy
    @finish_time = FinishTime.find(params[:id])

    if @finish_time.destroy
      redirect_to dashboard_path, notice: "Finish time removed from ##{@finish_time.position}"
    else
      redirect_to dashboard_path, alert: @finish_time.errors.full_messages.to_sentence
    end
  end

  private

  def finish_time_params
    params.require(:finish_time).permit(:event_id, :position, :time_string)
  end
end
