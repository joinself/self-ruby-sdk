# frozen_string_literal: true

# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: header.proto

require 'google/protobuf'

require_relative 'msgtype_pb'
Google::Protobuf::DescriptorPool.generated_pool.build do
  add_file("header.proto", syntax: :proto3) do
    add_message "msgproto.Header" do
      optional :type, :enum, 1, "msgproto.MsgType"
      optional :id, :string, 2
    end
  end
end

module Msgproto
  Header = Google::Protobuf::DescriptorPool.generated_pool.lookup("msgproto.Header").msgclass
end
