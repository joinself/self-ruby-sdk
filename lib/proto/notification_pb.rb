# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: notification.proto

require 'google/protobuf'

require 'msgtype_pb'
require 'errtype_pb'
Google::Protobuf::DescriptorPool.generated_pool.build do
  add_message "msgproto.Notification" do
    optional :type, :enum, 1, "msgproto.MsgType"
    optional :id, :string, 2
    optional :error, :string, 3
    optional :errtype, :enum, 4, "msgproto.ErrType"
  end
end

module Msgproto
  Notification = Google::Protobuf::DescriptorPool.generated_pool.lookup("msgproto.Notification").msgclass
end
