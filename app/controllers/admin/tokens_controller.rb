require "csv"

class Admin::TokensController < ApplicationController
  include AdminAuthentication

  def index
    @tokens = (1..200).map do |position|
      {
        position: position,
        token_path: FinishPosition.token_path_for_position(position),
        full_url: claim_finish_token_url(*FinishPosition.token_path_for_position(position).split("/"))
      }
    end
  end

  def export
    tokens = (1..200).map do |position|
      token_path = FinishPosition.token_path_for_position(position)
      prefix, pos = token_path.split("/")
      {
        position: position,
        token_path: token_path,
        full_url: claim_finish_token_url(prefix, pos)
      }
    end

    csv_data = CSV.generate(headers: true) do |csv|
      csv << [ "Position", "Token Path", "Full URL" ]
      tokens.each do |token|
        csv << [ token[:position], token[:token_path], token[:full_url] ]
      end
    end

    send_data csv_data, filename: "finish_tokens_#{Date.today}.csv", type: "text/csv"
  end

  def print
    @tokens = (1..200).map do |position|
      token_path = FinishPosition.token_path_for_position(position)
      prefix, pos = token_path.split("/")
      {
        position: position,
        token_path: token_path,
        full_url: claim_finish_token_url(prefix, pos)
      }
    end
    render layout: false
  end
end
