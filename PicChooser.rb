require 'telegram/bot'
require 'httparty'

def getKeyboard(n)
  str = ""
  i = 1
  until i > n do
    str.concat(i.to_s)
    if i < n
      str.concat(" ")
    end
    i = i+1
  end

  return Telegram::Bot::Types::ReplyKeyboardMarkup
      .new(keyboard: str.split(" "), one_time_keyboard: true)
end

token = '953990220:AAFfbdRj1pBzMQB84fRCIASuR2DTgr0axYQ'

chat_id = "@PicChoosing"
text = "testiiiing"
url = "https://api.telegram.org/bot#{token}/sendMessage?chat_id=#{chat_id}&text=#{text}"

Telegram::Bot::Client.run(token) do |bot|
  messages = Array.new
  keyboard = Telegram::Bot::Types::ReplyKeyboardMarkup
      .new(keyboard: [%w(/new /get), %w(/start /stop)], one_time_keyboard: true)

  bot.listen do |message|
    case message.text
    when '/start'
      bot.api.send_message(chat_id: message.chat.id, text: "Hello, #{message.from.first_name}", reply_markup: keyboard)
    when '/new'
      bot.api.send_message(chat_id: message.chat.id, text: "Send me what you want to save.")
      bot.listen do |msg|
        messages.push(msg)
        break
      end
      bot.api.send_message(chat_id: message.chat.id, text: "Message received.", reply_markup: keyboard)
    when '/get'
      if messages.empty?
        bot.api.send_message(chat_id: message.chat.id, text: "Sorry, I have nothing to send. :(", reply_markup: keyboard)
      else
        bot.api.send_message(chat_id: message.chat.id, text: "Choose a number(1 - #{messages.length}):", reply_markup: getKeyboard(messages.length))
        bot.listen do |op|
          bot.api.send_message(chat_id: message.chat.id, text: messages.fetch(op.text.to_i-1, "That number doesn't work..."), reply_markup: keyboard)
          #messages.delete_at(op.text.to_i-1)
          break
        end
      end
    when '/done'
      response = HTTParty.get(url)
      bot.listen do |msg|
        bot.api.send_message(chat_id: message.chat.id, text:"Someone sent this: " + msg.text)
        break
      end
    when '/stop'
      bot.api.send_message(chat_id: message.chat.id, text: "Bye, #{message.from.first_name}", reply_markup: keyboard)
    end
  end
end
