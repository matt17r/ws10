class AdminUser
  def self.matches?(request)
    session_id = request.cookie_jar.signed["session_id"]
    user_session = session_id && ::Session.find_by(id: session_id)
    current_user = user_session&.user
    current_user.present? && current_user.respond_to?(:admin?) && current_user.admin?
  end
end
