module UsersHelper
  def sort_link(column, title, sort_column, sort_direction)
    # Determine the next direction when clicking this column
    if sort_column == column
      # If currently sorted by this column, toggle direction
      direction = sort_direction == "asc" ? "desc" : "asc"
    else
      # If not currently sorted by this column, use default direction for this column type
      direction = case column
      when "events", "runs", "volunteers"
                    "desc"  # Default to DESC for counts
      else
                    "asc"   # Default to ASC for names and times
      end
    end

    css_class = "text-left font-semibold text-gray-900 hover:text-[#DB2955] cursor-pointer"

    link_to users_path(sort: column, direction: direction), class: css_class do
      content = title.dup
      if sort_column == column
        arrow = sort_direction == "asc" ? " ↑" : " ↓"
        content += arrow
      end
      content.html_safe
    end
  end
end
