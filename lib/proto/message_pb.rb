# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: message.proto

require 'google/protobuf'

require_relative 'msgtype_pb'
require 'google/protobuf/timestamp_pb'
Google::Protobuf::DescriptorPool.generated_pool.build do
  add_message "msgproto.Message" do
    optional :type, :enum, 1, "msgproto.MsgType"
    optional :id, :string, 2
    optional :sender, :string, 3
    optional :recipient, :string, 4
    optional :ciphertext, :bytes, 5
    optional :timestamp, :message, 6, "google.protobuf.Timestamp"
    optional :offset, :int64, 7
  end
end

module Msgproto
  Message = Google::Protobuf::DescriptorPool.generated_pool.lookup("msgproto.Message").msgclass
end
