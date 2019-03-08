require_relative 'biggestbass'

class HTML
  def login_button
    <<~HTML
    <div style="float:right">
    <form method="POST" action="/biggestbass/sessions">
      Login: <input type="text" placeholder="Enter Username" name="username">
      <input type="password" placeholder="Enter Password" name="password">
      <input type="submit" value="Submit">
    </form>
    </div>
    HTML
  end

  def logout_button(user)
    <<~HTML
    <p align="right">[Logged in as: #{user}]</p>
    <div style="float:right">
    <form align="right" method="get" action="/change_password_ui">
      <button type="submit" name="action" value="submit">Change password</button>
      <button type="submit" name="action" formmethod="get" formaction="/logout">Logout</button>
    </form>
    </div>
    HTML
  end

  def submit_weight_button(user)
    <<~HTML
    <p align="left">Have an upgrade <b>#{user}</b>? Submit your <b>bullshit</b> catch below!</p>
    <p>(Input accepts either forms of weight measurement: lbs-oz (eg: 3-8) OR lbs-decimal (eg: 3.58))</p>
      <form method="POST" action="/biggestbass/submit">
        <input type="radio" name="fish_type" value="largemouth_weight" checked>&nbsp;&nbsp;Largemouth<br>
        <input type="radio" name="fish_type" value="smallmouth_weight">&nbsp;&nbsp;Smallmouth<br><br>
        <input type="text" placeholder="eg: 3-8 OR 3.58" name="upgrade_weight"><br>
        <input type="submit" value="Submit Upgrade">
      </form>
    HTML
  end

  def old_password_incorrect
    <<~HTML
    <p><font color="red">Error: Old password does NOT match</font></p>
    HTML
  end

  def new_passwords_not_match
    <<~HTML
    <p><font color="red">Error: New passwords do NOT match and/or field(s) are empty</font></p>
    HTML
  end

  def new_password_match_old
    <<~HTML
    <p><font color="red">Error: New password matches old password</font></p>
    HTML
  end

  def entry_fee_not_paid
    <<~HTML
    <p><font color="red">Error: Upgrade submission failed. Entry fee has not been paid.</font></p>
    HTML
  end

  def weight_upgrade_submission_failed
    <<~HTML
    <p><b>Reasons may include the following:</b><br>
      <ul>
      <li>Your entry fee has not been paid</li>
      <li>Weight submission field is empty</li>
      <li>Weight submission field contains letter characters</li>
    </ul><br>
    Please review the Global Actions History for more details.
    </p>
    HTML
  end
end
