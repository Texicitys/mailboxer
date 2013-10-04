class Message < ActiveRecord::Base
  #AJOUT DEPUIS NOTIFICATION
  attr_accessor :recipients
  attr_accessible :body, :subject, :global, :expires if Mailboxer.protected_attributes?

  belongs_to :sender, :polymorphic => :true
  belongs_to :notified_object, :polymorphic => :true
  has_many :receipts, :dependent => :destroy

  validates_presence_of :body#, :subject
  #FIN NOTIFICATION
  attr_accessible :attachment if Mailboxer.protected_attributes?

  belongs_to :conversation, :validate => true, :autosave => true
  validates_presence_of :sender

  class_attribute :on_deliver_callback
  protected :on_deliver_callback
  scope :conversation, lambda { |conversation|
    where(:conversation_id => conversation.id)
  }
  #AJOUT DEPUIS NOTIFICATION + modification de notifications en messages
  scope :recipient, lambda { |recipient|
    joins(:receipts).where('receipts.receiver_id' => recipient.id,'receipts.receiver_type' => recipient.class.base_class.to_s)
  }
  scope :with_object, lambda { |obj|
    where('notified_object_id' => obj.id,'notified_object_type' => obj.class.to_s)
  }
  scope :not_trashed, lambda {
    joins(:receipts).where('receipts.trashed' => false)
  }
  scope :unread,  lambda {
    joins(:receipts).where('receipts.is_read' => false)
  }
  scope :global, lambda { where(:global => true) }
  scope :expired, lambda { where("messages.expires < ?", Time.now) }
  scope :unexpired, lambda {
    where("messages.expires is NULL OR messages.expires > ?", Time.now)
  }
  #FIN NOTIFICATION

  mount_uploader :attachment, AttachmentUploader

  include Concerns::ConfigurableMailer

  class << self
    #Sets the on deliver callback method.
    def on_deliver(callback_method)
      self.on_deliver_callback = callback_method
    end

    ##Sends a Notification to all the recipients
    #def notify_all(recipients,subject,body,obj = nil,sanitize_text = true,notification_code=nil,send_mail=true)
    #  notification = Notification.new({:body => body, :subject => subject})
    #  notification.recipients = recipients.respond_to?(:each) ? recipients : [recipients]
    #  notification.recipients = notification.recipients.uniq if recipients.respond_to?(:uniq)
    #  notification.notified_object = obj if obj.present?
    #  notification.notification_code = notification_code if notification_code.present?
    #  notification.deliver sanitize_text, send_mail
    #end
    #
    ##Takes a +Receipt+ or an +Array+ of them and returns +true+ if the delivery was
    ##successful or +false+ if some error raised
    #def successful_delivery? receipts
    #  case receipts
    #    when Receipt
    #      receipts.valid?
    #      receipts.errors.empty?
    #    when Array
    #      receipts.each(&:valid?)
    #      receipts.all? { |t| t.errors.empty? }
    #    else
    #      false
    #  end
    #end
  end

  #Delivers a Message. USE NOT RECOMENDED.
  #Use Mailboxer::Models::Message.send_message instead.
  def deliver(reply = false, should_clean = true)
    self.clean if should_clean

    #Receiver receipts
    temp_receipts = recipients.map { |r| build_receipt(r, 'inbox') }

    #Sender receipt
    sender_receipt = build_receipt(sender, 'sentbox', true)
    temp_receipts << sender_receipt

    temp_receipts.each(&:valid?)
    if temp_receipts.all? { |t| t.errors.empty? }
      temp_receipts.each(&:save!) 	#Save receipts
      #Should send an email?
      if Mailboxer.uses_emails
        if Mailboxer.mailer_wants_array
          get_mailer.send_email(self, recipients).deliver
        else
          recipients.each do |recipient|
            email_to = recipient.send(Mailboxer.email_method, self)
            get_mailer.send_email(self, recipient).deliver if email_to.present?
          end
        end
      end
      if reply
        self.conversation.touch
      end
      self.recipients=nil
      self.on_deliver_callback.call(self) unless self.on_deliver_callback.nil?
    end
    sender_receipt
  end

  #AJOUT DEPUIS NOTIFICATION
  #Returns the recipients of the message
  def recipients
    if @recipients.blank?
      recipients_array = Array.new
      self.receipts.each do |receipt|
        recipients_array << receipt.receiver
      end

      recipients_array
    else
      @recipients
    end
  end

  #Returns the receipt for the participant
  def receipt_for(participant)
    Receipt.message(self).recipient(participant)
  end

  #Returns the receipt for the participant. Alias for receipt_for(participant)
  def receipts_for(participant)
    receipt_for(participant)
  end

  #Returns if the participant have read the message
  def is_unread?(participant)
    return false if participant.nil?
    !self.receipt_for(participant).first.is_read
  end

  def is_read?(participant)
    !self.is_unread?(participant)
  end

  #Returns if the participant have trashed the message
  def is_trashed?(participant)
    return false if participant.nil?
    self.receipt_for(participant).first.trashed
  end

  #Returns if the participant have deleted the message
  def is_deleted?(participant)
    return false if participant.nil?
    return self.receipt_for(participant).first.deleted
  end

  #Mark the message as read
  def mark_as_read(participant)
    return if participant.nil?
    self.receipt_for(participant).mark_as_read
  end

  #Mark the message as unread
  def mark_as_unread(participant)
    return if participant.nil?
    self.receipt_for(participant).mark_as_unread
  end

  #Move the message to the trash
  def move_to_trash(participant)
    return if participant.nil?
    self.receipt_for(participant).move_to_trash
  end

  #Takes the message out of the trash
  def untrash(participant)
    return if participant.nil?
    self.receipt_for(participant).untrash
  end

  #Mark the message as deleted for one of the participant
  def mark_as_deleted(participant)
    return if participant.nil?
    return self.receipt_for(participant).mark_as_deleted
  end

  include ActionView::Helpers::SanitizeHelper

  #Sanitizes the body and subject
  def clean
    unless self.subject.nil?
      self.subject = sanitize self.subject
    end
    self.body = sanitize self.body
  end

  #Returns notified_object. DEPRECATED
  def object
    warn "DEPRECATION WARNING: use 'notify_object' instead of 'object' to get the object associated with the Message"
    notified_object
  end

  #FIN NOTIFICATION

  private
  def build_receipt(receiver, mailbox_type, is_read = false)
    Receipt.new.tap do |receipt|
      #mis message à la place de notification
      receipt.message = self
      receipt.is_read = is_read
      receipt.receiver = receiver
      receipt.mailbox_type = mailbox_type
    end
  end
end
