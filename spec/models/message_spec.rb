require 'spec_helper'

describe Message do

  before do
    @entity1 = FactoryGirl.create(:user)
    @entity2 = FactoryGirl.create(:user)
    @entity3 = FactoryGirl.create(:user)
    @entity4 = FactoryGirl.create(:user)
    @receipt1 = @entity1.send_message(@entity2, "Body", "Subject")
    @receipt2 = @entity2.reply_to_all(@receipt1, "Reply body 1")
    @receipt3 = @entity1.reply_to_all(@receipt2, "Reply body 2")
    @receipt4 = @entity2.reply_to_all(@receipt3, "Reply body 3")
    @message1 = @receipt1.message
    @message4 = @receipt4.message
    @conversation = @message1.conversation
  end

  it "should have right recipients" do
    @receipt1.message.recipients.count.should==2
    @receipt2.message.recipients.count.should==2
    @receipt3.message.recipients.count.should==2
    @receipt4.message.recipients.count.should==2
  end

  it "should be able to be marked as deleted" do
    @receipt1.deleted.should==false
    @message1.mark_as_deleted @entity1
    @message1.is_deleted?(@entity1).should==true
  end

  #Ajout depuit notification
  #it "should notify one user" do
  #  @entity1.notify("Subject", "Body")
  #
  #  #Check getting ALL receipts
  #  @entity1.mailbox.receipts.size.should==1
  #  receipt      = @entity1.mailbox.receipts.first
  #  message = receipt.message
  #  message.subject.should=="Subject"
  #  message.body.should=="Body"
  #
  #  #Check getting message receipts only
  #  @entity1.mailbox.messages.size.should==1
  #  message = @entity1.mailbox.messages.first
  #  message.subject.should=="Subject"
  #  message.body.should=="Body"
  #end

  it "should be unread by default" do
    @entity1.send_message(@entity2, "Subject", "Body")
    @entity2.mailbox.receipts.size.should==5
    message = @entity2.mailbox.receipts.first.message
    message.should be_is_unread(@entity2)
  end

  it "should be able to marked as read" do
    @entity1.send_message(@entity2, "Subject", "Body")
    @entity2.mailbox.receipts.size.should==5
    message = @entity2.mailbox.receipts.first.message
    message.mark_as_read(@entity2)
    message.should be_is_read(@entity2)
  end

  #it "should notify several users" do
  #  recipients = [@entity1, @entity2, @entity3]
  #  @entity4.send_message(recipients, "Subject", "Body")
  #
  #  #Check getting ALL receipts
  #  @entity1.mailbox.receipts.size.should==5
  #  receipt = @entity1.mailbox.receipts.first
  #  message = receipt.message
  #  message.subject.should=="Subject"
  #  message.body.should=="Body"
  #  @entity2.mailbox.receipts.size.should==5
  #  receipt = @entity2.mailbox.receipts.first
  #  message = receipt.message
  #  message.subject.should=="Subject"
  #  message.body.should=="Body"
  #  @entity3.mailbox.receipts.size.should==1
  #  receipt = @entity3.mailbox.receipts.first
  #  message = receipt.message
  #  message.subject.should=="Subject"
  #  message.body.should=="Body"
  #
  #  #Check getting message receipts only
  #  @entity1.mailbox.messages.size.should==1
  #  message = @entity1.mailbox.messages.first
  #  message.subject.should=="Subject"
  #  message.body.should=="Body"
  #  @entity2.mailbox.messages.size.should==1
  #  message = @entity2.mailbox.messages.first
  #  message.subject.should=="Subject"
  #  message.body.should=="Body"
  #  @entity3.mailbox.messages.size.should==1
  #  message = @entity3.mailbox.messages.first
  #  message.subject.should=="Subject"
  #  message.body.should=="Body"
  #
  #end

  #it "should notify a single recipient" do
  #  @entity4.send_message(@entity1, "Subject", "Body")
  #
  #  #Check getting ALL receipts
  #  @entity1.mailbox.receipts.size.should==5
  #  receipt = @entity1.mailbox.receipts.first
  #  message = receipt.message
  #  message.subject.should=="Subject"
  #  message.body.should=="Body"
  #
  #  #Check getting message receipts only
  #  @entity1.mailbox.messages.size.should==5
  #  message = @entity1.mailbox.messages.first
  #  message.subject.should=="Subject"
  #  message.body.should=="Body"
  #end

#  describe "#expire" do
#    subject { Message.new }
#
#    describe "when the message is already expired" do
#      before do
#        subject.stub(:expired? => true)
#      end
#      it 'should not update the expires attribute' do
#        subject.should_not_receive :expires=
#        subject.should_not_receive :save
#        subject.expire
#      end
#    end
#
#    describe "when the message is not expired" do
#      let(:now) { Time.now }
#      let(:one_second_ago) { now - 1.second }
#      before do
#        Time.stub(:now => now)
#        subject.stub(:expired? => false)
#      end
#      it 'should update the expires attribute' do
#        subject.should_receive(:expires=).with(one_second_ago)
#        subject.expire
#      end
#      it 'should not save the record' do
#        subject.should_not_receive :save
#        subject.expire
#      end
#    end
#
#  end
#end
#
#describe "#expire!" do
#  subject { Message.new }
#
#  describe "when the message is already expired" do
#    before do
#      subject.stub(:expired? => true)
#    end
#    it 'should not call expire' do
#      subject.should_not_receive :expire
#      subject.should_not_receive :save
#      subject.expire!
#    end
#  end
#
#  describe "when the message is not expired" do
#    let(:now) { Time.now }
#    let(:one_second_ago) { now - 1.second }
#    before do
#      Time.stub(:now => now)
#      subject.stub(:expired? => false)
#    end
#    it 'should call expire' do
#      subject.should_receive(:expire)
#      subject.expire!
#    end
#    it 'should save the record' do
#      subject.should_receive :save
#      subject.expire!
#    end
#  end
#
#end
#
#describe "#expired?" do
#  subject { Message.new }
#  context "when the expiration date is in the past" do
#    before { subject.stub(:expires => Time.now - 1.second) }
#    it 'should be expired' do
#      subject.expired?.should be_true
#    end
#  end
#
#  context "when the expiration date is now" do
#    before {
#      time = Time.now
#      Time.stub(:now => time)
#      subject.stub(:expires => time)
#    }
#
#    it 'should not be expired' do
#      subject.expired?.should be_false
#    end
#  end
#
#  context "when the expiration date is in the future" do
#    before { subject.stub(:expires => Time.now + 1.second) }
#    it 'should not be expired' do
#      subject.expired?.should be_false
#    end
#  end
#
#  context "when the expiration date is not set" do
#    before {subject.stub(:expires => nil)}
#    it 'should not be expired' do
#      subject.expired?.should be_false
#    end
#  end

end

