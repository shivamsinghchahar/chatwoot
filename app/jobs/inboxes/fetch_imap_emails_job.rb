class Inboxes::FetchImapEmailsJob < ApplicationJob
  queue_as :low

  def perform(channel)
    Mail.defaults do
      retriever_method :imap, address: channel.imap_address,
                              port: channel.imap_port,
                              user_name: channel.imap_email,
                              password: channel.imap_password,
                              enable_ssl: channel.imap_enable_ssl
    end

    new_mails = false

    Mail.find(what: :last, count: 10, order: :desc).each do |mail|
      if mail.date.utc >= channel.imap_inbox_synced_at
        Imap::ImapMailbox.new.process(mail)
        new_mails = true
      end
    end

    Channel::Email.update(channel.id, imap_inbox_synced_at: Time.now.utc) if new_mails
  end
end
