# Copyright 2020 Self Group Ltd. All Rights Reserved.

# frozen_string_literal: true
require_relative '../test_helper'
require 'rspec/mocks/minitest_integration'
require 'selfsdk'

require 'webmock/minitest'

class Group < Minitest::Test
  describe 'invite' do
    let(:chat) { double("chat") }
    let(:gid) { "gid" }
    let(:group_name) { "group" }
    let(:members) { ["A", "B", "C"] }
    let(:result) { "r" }
    let(:body) { "hi there!" }
    let(:group) do
      SelfSDK::Chat::Group.new(chat,  gid: gid,
                                      name: group_name,
                                      members: members )
    end

    describe "empty user" do
      let(:group_name) { "" }

      def test_empty_group_invitation
        _{ group.invite(group_name) }.must_raise StandardError
      end
    end

    describe "group invitation" do
      def test_group_invitation
        expect(chat).to receive(:invite).with(gid, group_name, members).and_return(result)
        assert_equal group.invite(group_name), result
      end
    end

    describe "leave group" do
      def test_leave_group
        expect(chat).to receive(:leave).with(gid, members).and_return(result)
        assert_equal group.leave(), result
      end
    end

    describe "join group" do
      def test_join_group
        expect(chat).to receive(:join).with(gid, members).and_return(result)
        assert_equal group.join(), result
      end
    end

    describe "message" do
      def test_message_group
        expect(chat).to receive(:message).with(members, body, {gid: gid}).and_return(result)
        assert_equal group.message(body), result
      end
    end

    describe "message_with_otps" do
      let(:opts) { { a: 'b' } }
      def test_message_group
        expect(chat).to receive(:message).with(members, body, {gid: gid, a: 'b'}).and_return(result)
        assert_equal group.message(body, opts), result
      end
    end
  end
end