# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: header.proto

require 'google/protobuf'

require 'msgtype_pb'
Google::Protobuf::DescriptorPool.generated_pool.build do
  add_message "msgproto.Header" do
    optional :type, :enum, 1, "msgproto.MsgType"
    optional :id, :string, 2
  end
end

module Msgproto
  Header = Google::Protobuf::DescriptorPool.generated_pool.lookup("msgproto.Header").msgclass
end
