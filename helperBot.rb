require 'telegram/bot'

token = '956954363:AAEym6qzcLahtkGnAxjKMCVLakaa8lkaoV4'
chat_id = 299523989

Telegram::Bot::Client.run(token) do |bot|

  bot.listen do |message|

      bot.api.send_message(chat_id: chat_id, text: message.text)
  end
end
