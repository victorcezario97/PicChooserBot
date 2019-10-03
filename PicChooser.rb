require 'telegram/bot'
require 'ostruct'

token = '953990220:AAFfbdRj1pBzMQB84fRCIASuR2DTgr0axYQ'

@keyboard = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w(/new /send), %w(/get /all), %w(/remove /clear), %w(/help /stop)], one_time_keyboard: false)
@done_keyboard = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w(/done)], one_time_keyboard: true)
@saved = Array.new
@active_user = OpenStruct.new
@other_user = OpenStruct.new
@running = false

def oneWordKeyboard(str)
  return Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [str], one_time_keyboard: true)
end

def getInlineKeyboard(n, extra)
  kb = [n]

  for i in 0..n-1
    kb[i] = Telegram::Bot::Types::InlineKeyboardButton.new(text: (i+1).to_s, callback_data: i)
  end
  if extra != nil
    kb[n] = Telegram::Bot::Types::InlineKeyboardButton.new(text: extra, callback_data: -1)
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
  elsif msg.text != nil
    if msg.text == "/done"
      return nil
    end
    media.type = "message"
    media.id = msg.text
  else return nil
  end

  media.caption = msg.caption

  bot.api.send_message(chat_id: msg.chat.id, text: "#{media.type.capitalize()} received", reply_markup: @done_keyboard)
  return media
end

def sendMedia(id, media, bot)
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

  when "message"
    bot.api.send_message(chat_id: id, text: media.id)
  end
end

def sendQuery(bot)

  bot.api.send_message(chat_id: @other_user.id, text: "Choose a number:", reply_markup: getInlineKeyboard(@saved.length, nil))
  bot.api.send_message(chat_id: @active_user.id, text: "Waiting for the response...", reply_markup: @keyboard)
  bot.listen do |msg|

    case msg

    when Telegram::Bot::Types::CallbackQuery
      if msg.data.to_i >= 0 && msg.data.to_i <= @saved.length
        sendMedia(@other_user.id, @saved[msg.data.to_i], bot)
        @saved.clear
        bot.api.answerCallbackQuery(callback_query_id: msg.id)
        bot.api.send_message(chat_id: @active_user.id, text: "An option has been picked(#{msg.data.to_i}). Clearing the message pool.")
        return
      else
        bot.api.send_message(chat_id: @other_user.id, text: "That number doesn't work...")
        bot.api.answerCallbackQuery(callback_query_id: msg.id)
      end
    end
  end
end

def sendEverything(id, bot)
  @saved.each do |media|
    sendMedia(@active_user.id, media, bot)
  end
end

def sendHelp(id, bot)
  text = "PicChooserBot Usage:
  /new - Start a new message pool or add to the one that already exists, to send to the other chat. The bot will ask for the messages or media after receiving this message. Send '/done' after finishing sending everything you want.
  /send - Send the choice of picking one of the messages to the other chat. After a message has been picked and sent, the message pool will be erased.
  /get - Get a specific message from the current message pool.
  /all - See all the messages in the current message pool.
  /remove - Remove a specific message from the current message pool.
  /clear - Deletes the whole message pool.
  /help - Show this text.
  /stop - Stops the bot (necessary so the other person can use it)."

  bot.api.send_message(chat_id: id, text: text, reply_markup: @keyboard)
end

def remove(bot)
  bot.api.send_message(chat_id: @active_user.id, text: "Choose a number to remove:", reply_markup: getInlineKeyboard(@saved.length, "Cancel"))
  bot.listen do |msg|
    op = msg.data.to_i

    case msg
    when Telegram::Bot::Types::CallbackQuery
      if op >= 0 && op < @saved.length
        @saved.delete_at(msg.data.to_i)
        bot.api.send_message(chat_id: @active_user.id, text: "Message removed.")
        bot.api.answerCallbackQuery(callback_query_id: msg.id)
        break
      elsif op == -1
        bot.api.send_message(chat_id: @active_user.id, text: "Operation cancelled.")
        bot.api.answerCallbackQuery(callback_query_id: msg.id)
        break
      else
        bot.api.send_message(chat_id: @active_user.id, text: "That number doesn't work...")
        bot.api.answerCallbackQuery(callback_query_id: msg.id)
      end


    when Telegram::Bot::Types::Message
      if msg.text == "/cancel"
        bot.api.send_message(chat_id: @active_user.id, text: "Cancelling...")
        break
      end
    end
  end
end

def clearMessages(bot)
  buttons = []
  buttons[0] = Telegram::Bot::Types::InlineKeyboardButton.new(text: "Yes", callback_data: 0)
  buttons[1] = Telegram::Bot::Types::InlineKeyboardButton.new(text: "No", callback_data: 1)

  kb = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: buttons)

  bot.api.send_message(chat_id: @active_user.id, text:"Are you sure you want to delete all messages in the pool (#{@saved.length}) ?", reply_markup: kb)

  bot.listen do |op|
    case op
    when Telegram::Bot::Types::CallbackQuery
      if op.data.to_i == 0
        @saved.clear
        bot.api.send_message(chat_id: @active_user.id, text:"Message pool deleted.")
      else
        bot.api.send_message(chat_id: @active_user.id, text:"Operation cancelled.")
      end
      bot.api.answerCallbackQuery(callback_query_id: op.id)
      break

    end
  end
end

def handleMessage(message, bot)

  case message.text
  when '/start'
    bot.api.send_message(chat_id: message.chat.id, text: "Hello, #{message.from.first_name}, please choose an option.", reply_markup: @keyboard)

  when '/new'
    bot.api.send_message(chat_id: @active_user.id, text: "Send me what you want to save and then send /done.", reply_markup: @done_keyboard)
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
    bot.api.send_message(chat_id: @active_user.id, text: "Messages received.", reply_markup: @keyboard)

  when '/get'
    if @saved.empty?
      bot.api.send_message(chat_id: @active_user.id, text: "Sorry, I have nothing to send. :(", reply_markup: @keyboard)
    else
      bot.api.send_message(chat_id: @active_user.id, text: "Choose a number:", reply_markup: getInlineKeyboard(@saved.length, nil))
      bot.listen do |op|
        case op
        when Telegram::Bot::Types::CallbackQuery
          i = op.data.to_i
          if i >= 0 && i < @saved.length
            sendMedia(@active_user.id, @saved[i], bot)
          end
          bot.api.answerCallbackQuery(callback_query_id: op.id)
          break

        end
      end
    end

  when '/remove'
    if @saved.empty?
      bot.api.send_message(chat_id: @active_user.id, text: "There's nothing to remove.")
    else
      remove(bot)
    end

  when "/all"
    if @saved.empty?
      bot.api.send_message(chat_id: @active_user.id, text:"You haven't sent me anything.")
    else
      sendEverything(@active_user.id, bot)
    end

  when '/send'
    if @saved.empty?
      bot.api.send_message(chat_id: @active_user.id, text:"You haven't sent me anything.")
    else
      sendQuery(bot)
      @running = false
      return
    end

  when '/help'
    sendHelp(@active_user.id, bot)

  when '/clear'
    if @saved.empty?
      bot.api.send_message(chat_id: @active_user.id, text:"There's nothing to delete.")
    else
      clearMessages(bot)
    end

  when '/stop'
    bot.api.send_message(chat_id: @active_user.id, text: "Bye, #{message.from.first_name}", reply_markup: @keyboard)
    @running = false
    return

  else
    bot.api.send_message(chat_id: @active_user.id, text: "I'm sorry, I can't understand that. Use /help to see all the available commands.", reply_markup: @keyboard)
  end
end

file = File.open('chat_ids', 'r')
content = file.read
chat1 = content.split("\n")[0]
chat2 = content.split("\n")[1]

Telegram::Bot::Client.run(token) do |bot|
  time_start = 0
  
  bot.listen do |message|
    if @running
      if Time.now - time_start > 1800
        bot.api.send_message(chat_id: @active_user.id, text: "Operation timed out.")
        @active_user.id = nil
        @active_user.name = nil
        @other_user.id = nil
        @running = false
        @saved.clear
      end
    end


    case message

    when Telegram::Bot::Types::Message
      if !@running
        if message.chat.id.to_s == chat1
          @active_user.id = chat1
          @active_user.name = message.from.first_name
          @other_user.id = chat2
          @running = true
          time_start = Time.now
        elsif message.chat.id.to_s == chat2
          @active_user.id = chat2
          @active_user.name = message.from.first_name
          @other_user.id = chat1
          @running = true
        else
          @active_user.id = nil
          @active_user.name = nil
          @other_user.id = nil
        end
      end

      if message.chat.id.to_s == @active_user.id
        handleMessage(message, bot)
      else
        bot.api.send_message(chat_id: message.chat.id, text: "Sorry, I'm a bit busy right now, I'm helping #{@active_user.name}.")
      end
    end
  end
end
