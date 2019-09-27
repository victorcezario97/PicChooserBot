require 'telegram/bot'
require 'httparty'
require 'ostruct'

token = '953990220:AAFfbdRj1pBzMQB84fRCIASuR2DTgr0axYQ'

chat_id = "@PicChoosing"
url = "https://api.telegram.org/bot#{token}/sendMessage?chat_id=#{chat_id}&text="
@keyboard = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w(/new /remove), %w(/get /send)], one_time_keyboard: false)
@done_keyboard = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w(/done)], one_time_keyboard: true)
@saved = Array.new

def getInlineKeyboard(n, extra)
  kb = [n]

  for i in 0..n-1
    kb[i] = Telegram::Bot::Types::InlineKeyboardButton.new(text: (i+1).to_s, callback_data: i)
  end

  return Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
end

def handleMedia(msg, bot, type)

  media = OpenStruct.new
  media.type = type
  if type == "photo"
    media.id = msg.photo.first.file_id
  else
#    media.id = msg.
  end
  media.caption = msg.caption

  bot.api.send_message(chat_id: msg.chat.id, text: "Photo received", reply_markup: @done_keyboard)
  return photo
end

def handleMessage(message, bot)

  case message.text
  when '/start'
    puts message.chat.id
    bot.api.send_message(chat_id: message.chat.id, text: "Hello, #{message.from.first_name}", reply_markup: @keyboard)

  when '/new'
    bot.api.send_message(chat_id: message.chat.id, text: "Send me what you want to save.", reply_markup: @done_keyboard)
    bot.listen do |msg|
      if msg.text == "/done"
        break
      end
      @saved.push(handlePhoto(msg, bot))
    end
    bot.api.send_message(chat_id: message.chat.id, text: "Messages received.", reply_markup: @keyboard)

  when '/get'
    if @saved.empty?
      bot.api.send_message(chat_id: message.chat.id, text: "Sorry, I have nothing to send. :(", reply_markup: @keyboard)
    else
      bot.api.send_message(chat_id: message.chat.id, text: "Choose a number(1 - #{@saved.length}):", reply_markup: getInlineKeyboard(@saved.length, ""))
      bot.listen do |op|
        bot.api.send_message(chat_id: message.chat.id, text: @saved.fetch(op.text.to_i-1, "That number doesn't work..."), reply_markup: @keyboard)
        #@saved.delete_at(op.text.to_i-1)
        break
      end
    end

  when '/send'
    puts @saved.length
    if @saved.length > 0
      sendAll(bot)
    else
      bot.api.send_message(chat_id: message.chat.id, text:"You haven't sent me anything.")
    end

  when '/stop'
    bot.api.send_message(chat_id: message.chat.id, text: "Bye, #{message.from.first_name}", reply_markup: @keyboard)
  end
end

def sendAll(bot)

  bot.api.send_message(chat_id: '@PicChoosing', text: "Choose a number(1 - #{@saved.length}):", reply_markup: getInlineKeyboard(@saved.length, ""))
  bot.listen do |msg|
    case msg
    when Telegram::Bot::Types::CallbackQuery
      #bot.api.send_message(chat_id: message.chat.id, text:"Someone sent this: " + msg.text)
      if msg.data.to_i >= 0 && msg.data.to_i <= @saved.length
        #HTTParty.get(url + @saved.at(msg.text.to_i-1).text)
        bot.api.send_photo(chat_id: '@PicChoosing', photo: @saved[msg.data.to_i].id, caption: @saved[msg.data.to_i].caption)
        break
      else
        bot.api.send_message(chat_id: '@PicChoosing', text: "That number doesn't work...")
      end
    end
  end

end

file = File.open('chat_ids', 'r')
content = file.read
chat1 = content.split("\n")[0]
chat2 = content.split("\n")[1]

puts chat1
puts chat2

Telegram::Bot::Client.run(token) do |bot|

  bot.api.send_message(chat_id: chat1, text: "aThat number doesn't work...")
  bot.api.send_message(chat_id: chat2, text: "bThat number doesn't work...")

  bot.listen do |message|
    puts message.chat.id

    case message
    when Telegram::Bot::Types::Message
      handleMessage(message, bot)

    when Telegram::Bot::Types::PhotoSize
      handlePhoto(message, bot)


    end


  end
end
