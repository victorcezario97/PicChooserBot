require 'telegram/bot'
require 'httparty'
require 'ostruct'

token = '953990220:AAFfbdRj1pBzMQB84fRCIASuR2DTgr0axYQ'

chat_id = "@PicChoosing"
url = "https://api.telegram.org/bot#{token}/sendMessage?chat_id=#{chat_id}&text="
@keyboard = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w(/new /remove), %w(/get /send)], one_time_keyboard: false)
@done_keyboard = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w(/done)], one_time_keyboard: true)
@saved = Array.new

def oneWordKeyboard(str)
  return Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [str], one_time_keyboard: true)
end

def getInlineKeyboard(n, extra)
  kb = [n]

  for i in 0..n-1
    kb[i] = Telegram::Bot::Types::InlineKeyboardButton.new(text: (i+1).to_s, callback_data: i)
  end

  return Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: kb)
end

def handleMedia(msg, bot)

  media = OpenStruct.new

  if msg.photo.length > 0
    media.type = "photo"
    media.id = msg.photo.first.file_id
  elsif msg.voice != nil
    media.type = "voice"
    media.id = msg.voice.file_id
  elsif msg.video_note != nil
    media.type = "video_note"
    media.id = msg.video_note.file_id
  elsif msg.video != nil
    media.type = "video"
    media.id = msg.video.file_id
  elsif msg.sticker != nil
    media.type = "sticker"
    media.id = msg.sticker.file_id
  elsif msg.audio != nil
    media.type = "audio"
    media.id = msg.audio.file_id
  elsif msg.animation != nil
    media.type = "animation"
    media.id = msg.animation.file_id
  else return nil
  end

  media.caption = msg.caption

  bot.api.send_message(chat_id: msg.chat.id, text: "#{media.type.capitalize()} received", reply_markup: @done_keyboard)
  return media
end

def sendEverything(id, bot)
  @saved.each do |media|
    case media.type
    when "photo"
      bot.api.send_photo(chat_id: id, photo: media.id, caption: media.caption)

    when "voice"
      bot.api.send_voice(chat_id: id, voice: media.id, caption: media.caption)

    when "video_note"
      bot.api.send_video_note(chat_id: id, video_note: media.id)

    when "video"
      bot.api.send_video(chat_id: id, video: media.id, caption: media.caption)

    when "sticker"
      bot.api.send_sticker(chat_id: id, sticker: media.id)

    when "audio"
      bot.api.send_audio(chat_id: id, audio: media.id, caption: media.caption)

    when "animation"
      bot.api.send_animation(chat_id: id, animation: media.id, caption: media.caption)

    end
  end
end

def handleMessage(message, bot)

  case message.text
  when '/start'
    puts message.chat.id
    bot.api.send_message(chat_id: message.chat.id, text: "Hello, #{message.from.first_name}", reply_markup: @keyboard)

  when '/new'
    bot.api.send_message(chat_id: message.chat.id, text: "Send me what you want to save.", reply_markup: @done_keyboard)
    bot.listen do |msg|

      media = handleMedia(msg, bot)
      if media != nil
        @saved.push(media)
      else
        if msg.text == "/done"
          break
        end
      end
    end
    bot.api.send_message(chat_id: message.chat.id, text: "Messages received.", reply_markup: @keyboard)

  when '/get'
    if @saved.empty?
      bot.api.send_message(chat_id: message.chat.id, text: "Sorry, I have nothing to send. :(", reply_markup: @keyboard)
    else
      bot.api.send_message(chat_id: message.chat.id, text: "Choose a number(1 - #{@saved.length}):", reply_markup: getInlineKeyboard(@saved.length, ""))
      bot.listen do |op|
        bot.api.send_message(chat_id: message.chat.id, text: @saved.fetch(op.text.to_i-1, "That number doesn't work..."), reply_markup: @keyboard)
        break
      end
    end

  when '/remove'
    bot.api.send_message(chat_id: message.chat.id, text: "Choose a number(1 - #{@saved.length}) to remove:", reply_markup: getInlineKeyboard(@saved.length, ""))
    bot.listen do |msg|
      case msg
      when Telegram::Bot::Types::CallbackQuery
        if msg.data.to_i >= 0 && msg.data.to_i <= @saved.length
          @saved.delete_at(msg.data.to_i)
          bot.api.send_message(chat_id: message.chat.id, text: "Message removed")
          break
        else
          bot.api.send_message(chat_id: message.chat.id, text: "That number doesn't work...")
        end

      when Telegram::Bot::Types::Message
        if msg.text == "/cancel"
          bot.api.send_message(chat_id: message.chat.id, text: "Cancelling...")
          break
        end
      end
    end


  when "/all"
    sendEverything(message.chat.id, bot)

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
      if msg.data.to_i >= 0 && msg.data.to_i <= @saved.length
        bot.api.send_photo(chat_id: '@PicChoosing', photo: @saved[msg.data.to_i].id, caption: @saved[msg.data.to_i].caption)
        break
      else
        bot.api.send_message(chat_id: '@PicChoosing', text: "That number doesn't work...")
      end
    end
  end

  @saved.clear
end

file = File.open('chat_ids', 'r')
content = file.read
chat1 = content.split("\n")[0]
chat2 = content.split("\n")[1]

puts chat1
puts chat2

Telegram::Bot::Client.run(token) do |bot|

  bot.listen do |message|
    case message
    when Telegram::Bot::Types::Message
      handleMessage(message, bot)

    when Telegram::Bot::Types::PhotoSize
      handleMedia(message, bot, "photo")


    end


  end
end
