require 'telegram/bot'

token = '953990220:AAFfbdRj1pBzMQB84fRCIASuR2DTgr0axYQ'

Telegram::Bot::Client.run(token) do |bot|
  messages = Array.new
  bot.listen do |message|
    case message.text
    when '/start'
      bot.api.send_message(chat_id: message.chat.id, text: "Hello, #{message.from.first_name}")
    when '/new'
      bot.api.send_message(chat_id: message.chat.id, text: "Send me what you want to save.")
      bot.listen do |msg|
        messages.push(msg)
        break
      end
      bot.api.send_message(chat_id: message.chat.id, text: "Message received.")
    when '/get'
      if messages.empty?
        bot.api.send_message(chat_id: message.chat.id, text: "Sorry, I have nothing to send. :(")
      else
        bot.api.send_message(chat_id: message.chat.id, text: "Choose a number(1 - #{messages.length}):")
        bot.listen do |op|
          bot.api.send_message(chat_id: message.chat.id, text: messages.fetch(op.text.to_i-1, "That number doesn't work..."))
          messages.delete_at(op.text.to_i-1)
          break
        end
      end
    when '/stop'
      bot.api.send_message(chat_id: message.chat.id, text: "Bye, #{message.from.first_name}")
    end
  end
end
